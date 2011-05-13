# Simple steps
Given /^I see no dashboard$/ do
  page.has_no_xpath?("//table[@id='package']")
end

Then /^I should see (.+) with a dashboard\.$/ do |arg1|
  assert_equal path_to(arg1), current_path
  page.has_xpath?("//table[@id='package']")
end

Then /^I should see the login error "([^"]*)"$/ do |arg1|
  assert_not_equal "", arg1, "Error may not be empty!"
  assert_equal "/user_sessions", current_path
  find(:xpath, "//div[@id='errorExplanation']").has_content?(arg1)
end


# Complex steps - mainly to be used in other scenarios
Given /^I am logged in as "([^"]*)" with password "([^"]*)"/ do |login, password|
  visit "/user_sessions/new"
  fill_in("Login", :with => login)
  fill_in("Password", :with => password)
  click_button("Login")

  assert_equal "/", current_path
  page.has_xpath?("//table[@id='package']")
end
