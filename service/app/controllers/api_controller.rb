class ApiController < ApplicationController
  @@CURRENT_VERSION = "v1"

  @@SUPPORTED_VERSIONS = [ "v1" ]

  @@ERROR_CODES = {
    :ok                       => [     0, "ok", 200 ],
    :unknown                  => [ 10000, "Unknown error", 500 ],

    :invalid_signature        => [ 10001, "Invalid signature", 403 ],
    :not_authorized           => [ 10003, "Not authorized", 403 ],

#    :profile_does_not_exist   => [ 20003, "Profile does not exist", 404 ],
#    :profile_not_specified    => [ 20004, "No profile ID given", 500 ],
#    :missing_parameter        => [ 20005, "Missing parameter", 500 ],
#    :testrun_does_not_exist   => [ 20006, "Specified test run does not exist", 404 ],
  }


  def stacktrace
    return if is_invalid_request?(params)
    # FIXME
    api_response(:ok)
  end

private
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
    cloned.delete :controller
    cloned.delete :action
    cloned.delete :signature

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

#    require 'pp'
#    pp params
#    pp secret
#    pp signature

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
