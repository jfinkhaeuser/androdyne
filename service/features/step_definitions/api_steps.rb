Given /^an app with app ID "([^"]*)" submits a stacktrace$/ do |app_id|
  require 'digest/sha1'

  trace_data = 'TRACE_DATA'
  hash = Digest::SHA1.hexdigest(trace_data)

  @params = {
    :package_id   =>  app_id,
    :version_code =>  1,
    :version      =>  "0.1-alpha0",
    :trace        =>  trace_data,
    :hash         =>  hash,
    :phone        =>  "Nexus One",
    :os_version   =>  "2.3.3",
  }
end


Given /^the request signature is calculated to be "([^"]*)"$/ do |sig|
  @params[:signature] = sig
end


Then /^the HTTP status code should be "([^"]*)"$/ do |code|
  @response = post("/api/v1/stacktrace", @params)
  assert_equal code.to_i, @response.status
end


Then /^the response code should be "([^"]*)"$/ do |code|
  json = JSON.parse(@response.body)
  assert_equal code.to_i, json["error"]["code"]
end

