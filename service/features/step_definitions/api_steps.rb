Given /^an app with app ID "([^"]*)" submits a stacktrace$/ do |app_id|
  @params = {
    :package_id   =>  app_id,
    :version_code =>  1,
    :version      =>  "0.1-alpha0",
    :trace        =>  'TRACE_DATA',
    :phone        =>  "Nexus One",
    :os_version   =>  "2.3.3",
  }
end


Given /^the request signature is calculated to be "([^"]*)"$/ do |sig|
  @params[:signature] = sig
end


Given /^the app submits the same stacktrace "([^"]*)" times$/ do |count|
  count.to_i.times { |i|
    @response = post("/api/v1/stacktrace", @params)
  }
end


Then /^the HTTP status code should be "([^"]*)"$/ do |code|
  @response = post("/api/v1/stacktrace", @params)
  assert_equal code.to_i, @response.status
end


Then /^the response code should be "([^"]*)"$/ do |code|
  @json = JSON.parse(@response.body)
  assert_equal code.to_i, @json["error"]["code"]
end


Then /^the response body should contain the ID of the new stacktrace$/ do
  assert_equal 1, @json["content"]["stacktrace_id"]
end


Then /^the occurrence count should be "([^"]*)"$/ do |count|
  assert_equal count.to_i, @json["content"]["occurrences"]
end
