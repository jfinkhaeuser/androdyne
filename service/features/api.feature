Feature: API
  In order to allow apps to interact with the web service
  apps must be able to submit stack traces and log messages.

  Scenario Outline: API Verification
    Given an app with app ID "<App ID>" submits a stacktrace
    And the request signature is calculated to be "<Signature>"
    Then the HTTP status code should be "<HTTP Code>"
    And the response code should be "<Response Code>"

  Examples:
    | App ID        | Signature                                | HTTP Code | Response Code |
    | com.test.app  | e0755bd3e93840f8cd5ebd19d7e6ba20e0b1421c | 200       | 0             |
    | unknown.app   | e0755bd3e93840f8cd5ebd19d7e6ba20e0b1421c | 403       | 20002         |
    |               | e0755bd3e93840f8cd5ebd19d7e6ba20e0b1421c | 403       | 20002         |
    | com.test.app  | invalid_signature                        | 403       | 20001         |


  Scenario: Submit New Stacktrace
    Given an app with app ID "com.test.app" submits a stacktrace
    And the request signature is calculated to be "e0755bd3e93840f8cd5ebd19d7e6ba20e0b1421c"
    Then the HTTP status code should be "200"
    And the response code should be "0"
    And the response body should contain the ID of the new stacktrace
    And the occurrence count should be "1"


  Scenario: Submit Duplicate Stacktrace
    Given an app with app ID "com.test.app" submits a stacktrace
    And the request signature is calculated to be "e0755bd3e93840f8cd5ebd19d7e6ba20e0b1421c"
    And the app submits the same stacktrace "3" times
    Then the response code should be "0"
    And the response body should contain the ID of the new stacktrace
    And the occurrence count should be "3"


  Scenario: Submit New Log Trace
    Given an app with app ID "com.test.app" submits a stacktrace
    And the log tag is "TEST"
    And the log message is "Log Message"
    And the request signature is calculated to be "b6e09cec919f209a34af2d9f63d9ec9ba4023918"
    Then the HTTP status code should be "200"
    And the response code should be "0"
    And the response body should contain the ID of the new stacktrace
    And the occurrence count should be "1"


  Scenario: Submit Duplicate Log Trace
    Given an app with app ID "com.test.app" submits a stacktrace
    And the log tag is "TEST"
    And the log message is "Log Message"
    And the request signature is calculated to be "b6e09cec919f209a34af2d9f63d9ec9ba4023918"
    And the app submits the same stacktrace "3" times
    Then the response code should be "0"
    And the response body should contain the ID of the new stacktrace
    And the occurrence count should be "3"
