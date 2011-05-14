Feature: API
  In order to allow apps to interact with the web service
  apps must be able to submit stack traces and log messages.

  Scenario Outline: API Verification
    Given an app with app ID "<App ID>" submits a stacktrace
    And the request signature is calculated to be "<Signature>"
    Then the HTTP status code should be "<HTTP Code>"
    And the response code should be "<Response Code>"

  Examples:
    | App ID        | Signature                    | HTTP Code | Response Code |
    | com.test.app  | pPKq2YlEbRb1JhlDnpZNVGRMztQ= | 200       | 0             |
    | unknown.app   | pPKq2YlEbRb1JhlDnpZNVGRMztQ= | 403       | 20002         |
    |               | pPKq2YlEbRb1JhlDnpZNVGRMztQ= | 403       | 20002         |
    | com.test.app  | invalid_signature            | 403       | 20001         |
