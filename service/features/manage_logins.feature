@selenium
Feature: Manage logins
  In order to ensure the web service is accessible,
  users want to register and log in.

  Scenario Outline: Successful Login
    Given I am on the home page
    And I see no dashboard
    And I click on "Sign in"
    And I fill in "Login" with "<Login>"
    And I fill in "Password" with "<Password>"
    And I press the "Login" button
    Then I should see the home page with a dashboard.

    Examples:
      | Login  | Password |
      | test   | test123  |
      | foobar | 123test  |

  Scenario Outline: Failed Login
    Given I am on the home page
    And I see no dashboard
    And I click on "Sign in"
    And I fill in "Login" with "<Login>"
    And I fill in "Password" with "<Password>"
    And I press the "Login" button
    Then I should see the login error "<Error>"

    Examples:
      | Login  | Password | Error                 |
      | asdf   | test123  | Password is not valid |
      | foobar | test     | Login is not valid    |
