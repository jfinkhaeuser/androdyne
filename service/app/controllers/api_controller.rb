class ApiController < ApplicationController
  skip_before_filter :verify_authenticity_token

  @@CURRENT_VERSION = "v1"

  @@SUPPORTED_VERSIONS = [ "v1" ]

  @@ERROR_CODES = {
    :ok                           => [     0, "ok", 200 ],
    :unknown                      => [ 10000, "Unknown error", 500 ],
    :unsupported_api_version      => [ 10001, "Unsupported API version", 500 ],
    :unsupported_request_method   => [ 10002, "Unsupported request method", 500 ],
    :unknown_api_method           => [ 10003, "Unknown API method", 404 ],

    :invalid_signature            => [ 20001, "Invalid signature", 403 ],
    :not_authorized               => [ 20002, "Not authorized", 403 ],

    :write_error                  => [ 30001, "Could not write to the database", 500 ]
  }

  @@SUPPORTED_HTTP_METHODS = {
    :v1 => {
      :stacktrace => [ :post ]
    }
  }


  # Checks supported API versions, and dispatches to a versioned handler
  # method.
  def api_version_dispatch
    # First, version check.
    api_version = params[:api_version]
    if not @@SUPPORTED_VERSIONS.include?(api_version)
      return api_response(:unsupported_api_version)
    end

    # Generate method name
    method = params[:method].split('/')
    method = method.join('_')

    # Check request method is valid. If we have no definitions of request
    # methods for a call, we assume all methods are permitted.
    # Skip this in development mode, though.
    if ENV['RAILS_ENV'] != 'development'
      if @@SUPPORTED_HTTP_METHODS[api_version.to_sym] and @@SUPPORTED_HTTP_METHODS[api_version.to_sym][method.to_sym]
        supported_methods = @@SUPPORTED_HTTP_METHODS[api_version.to_sym][method.to_sym]
        req_method = request.method.downcase.to_sym
        if not supported_methods.include?(req_method)
          return api_response(:unsupported_request_method)
        end
      end
    end

    # Clean up params for send() to work properly
    params.delete(:api_version)
    params.delete(:method)
    params[:action] = method

    # Dispatch
    begin
      method = "#{api_version}_#{method}"
      return send(method.to_sym)
    rescue NoMethodError => e
      return api_response(:unknown_api_method)
    end
  end

private
  ############################################################################
  # V1 implementation
  def v1_stacktrace
    return if is_invalid_request?(params)

    # We know the package exists, so get it again.
    package = Package.where({:package_id => params[:package_id]})[0]

    # Decode trace data.
    trace_data = Base64.decode64(params[:trace])

    # Create a hash over the trace data. We'll use that to more quickly
    # look up a match.
    require 'digest/sha1'
    hash = Digest::SHA1.hexdigest(trace_data)

    # Try to find an existing/matching stack trace
    traces = Stacktrace.where({
      :package_id   => package.id,
      :version_code => params[:version_code],
      :hash         => hash,
    })

    trace = nil
    if traces.length > 0:
      trace = traces[0]
    end

    # All DB access is wrapped into a transaction.
    occurrence = nil
    begin
      Stacktrace.transaction do
        # If we haven't got a trace yet, create one. It's fine to save it
        # immediately; without adding an occurrence, it won't be counted in
        # the UI.
        if trace.nil?
          trace = Stacktrace.new({
            :package_id   => package.id,
            :version_code => params[:version_code],
            :hash         => hash,
            :version      => params[:version],
            :trace        => trace_data,
          })
          trace.save!
        end

        # Now that we've got a stacktrace, look for occurrences with the
        # given phone and os version.
        data = {
          :stacktrace_id  => trace.id,
          :phone          => params[:phone],
          :os_version     => params[:os_version],
        }
        occurrences = Occurrence.where(data)

        if occurrences.length > 0:
          occurrence = occurrences[0]
        end

        # Again, if we've found no occurrence, create it.
        if occurrence.nil?
          occurrence = Occurrence.new(data)
        else
          # Update the occurrence count.
          occurrence.count += 1
        end
        occurrence.save!

        # Finally, if part of the parameters include a log message, we'll
        # want to save that, too.
        if params[:tag] and params[:message]
          data = {
            :stacktrace_id  => trace.id,
            :tag            => params[:tag],
            :message        => Base64.decode64(params[:message]),
          }
          messages = LogMessage.where(data)

          if messages.length <= 0
            message = LogMessage.new(data)
            message.save!
          end
        end

      end # transaction end

    rescue ActiveRecord::RecordNotSaved => e
      return api_response(:write_error)
    end

    # Send the trace ID and occurrence count in responce.
    api_response(:ok, {
      :stacktrace_id  => trace.id,
      :occurrences    => occurrence.count,
    })
  end


  ############################################################################
  # Helper functions

  # Format an API response
  def api_response(*args) # :nodoc:
    code = args.first
    args.shift

    err = @@ERROR_CODES[code] || @@ERROR_CODES[:unknown]
    render :json => {
      :error => {
        :code => err[0],
        :message => err[1],
      },
      :content => args.first,
    }, :status => err[2]
  end

  # Validate request. This involves validation that the package ID exists,
  # but also that the parameters are signed with the correct package secret.
  def is_invalid_request?(params) # :nodoc:
    # Minimal test: ensure signature exists.
    if not params[:signature]
      return api_response(:invalid_signature)
    end

    # Validate package, and get secret
    if not params[:package_id]
      return api_response(:not_authorized)
    end

    packages = Package.where(:package_id => params[:package_id])
    if packages.length != 1
      return api_response(:not_authorized)
    end

    secret = packages[0].secret

    # Clone parameters for creating the signature. Then remove stuff we don't
    # want to see in the signature.
    cloned = Marshal::load(Marshal.dump(params))
    cloned.delete(:controller)
    cloned.delete(:action)
    cloned.delete(:signature)

    # Check signature
    signature = create_signature(cloned, secret)
    if not signature == params[:signature]
      return api_response(:invalid_signature, { :signature => signature })
    end
  end


  # Given parameters and a secret, create a valid signature
  def create_signature(params, secret) # :nodoc:
    query = build_nested_query(params)

    require 'openssl'
    digest = OpenSSL::Digest::Digest.new('sha1')
    signature = OpenSSL::HMAC.hexdigest(digest, secret, query)

    # require 'pp'
    # print '----------------------------------'
    # pp params
    # pp query
    # pp secret
    # pp signature

    return signature
  end

  # Sorts nested parameters and URL-encodes them
  def build_nested_query(value, prefix = nil)
    require 'rack/utils'
    case value
      when Array
        value.map { |v|
          build_nested_query(v, "#{prefix}[]")
        }.join("&")
      when Hash
        value.sort.map { |k, v|
          escaped = Rack::Utils.escape(k)
          build_nested_query(v, prefix ? "#{prefix}[#{escaped}]" : escaped)
        }.join("&")
      else
        raise ArgumentError, "value must be a Hash" if prefix.nil?
        "#{prefix}=#{Rack::Utils.escape(value)}"
    end
  end
end
