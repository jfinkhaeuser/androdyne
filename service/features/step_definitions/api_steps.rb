Given /^an app with app ID "([^"]*)" submits a stacktrace$/ do |app_id|
  # Semi-realistic trace data.
  trace = [
    "features/step_definitions/api_steps.rb:3",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/core_ext/instance_exec.rb:48:in `instance_exec'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/core_ext/instance_exec.rb:48:in `cucumber_instance_exec'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/core_ext/instance_exec.rb:69:in `cucumber_run_with_backtrace_filtering'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/core_ext/instance_exec.rb:36:in `cucumber_instance_exec'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/rb_support/rb_step_definition.rb:62:in `invoke'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/step_match.rb:26:in `invoke'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/step_invocation.rb:63:in `invoke'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/step_invocation.rb:42:in `accept'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:99:in `visit_step'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:164:in `broadcast'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:98:in `visit_step'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/step_collection.rb:15:in `accept'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/step_collection.rb:14:in `each'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/step_collection.rb:14:in `accept'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:93:in `visit_steps'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:164:in `broadcast'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/tree_walker.rb:92:in `visit_steps'",
    "vendor/gems/ruby/1.8/gems/cucumber-0.10.2/bin/../lib/cucumber/ast/scenario.rb:53:in `accept'",
  ].join("\n")

  @params = {
    :package_id   =>  app_id,
    :version_code =>  1,
    :version      =>  "0.1-alpha0",
    :trace        =>  Base64.encode64s(trace),
    :phone        =>  "Nexus One",
    :os_version   =>  "2.3.3",
  }
end


Given /^the request signature is calculated to be "([^"]*)"$/ do |sig|
  @params[:signature] = sig
end


Given /^the log tag is "([^"]*)"$/ do |tag|
  @params[:tag] = tag
end


Given /^the log message is "([^"]*)"$/ do |message|
  @params[:message] = Base64.encode64s(message)
end


Given /^the app submits the same stacktrace "([^"]*)" times$/ do |count|
  count.to_i.times { |i|
    @response = post("/api/v1/stacktrace", @params)
  }
end


Then /^the HTTP status code should be "([^"]*)"$/ do |code|
  # require 'pp'
  # pp @params
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
