class ApiController < ApplicationController
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

    # FIXME
    api_response(:ok)
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
    signature = Base64.encode64s(OpenSSL::HMAC.digest(digest, secret, query))

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
