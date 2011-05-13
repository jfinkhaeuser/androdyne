Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

Given /^I press the "([^"]*)" button$/ do |arg1|
  click_button(arg1)
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  fill_in(field, :with => value)
end

Given /^I click on "([^"]*)"$/ do |arg1|
  click_link(arg1)
end
