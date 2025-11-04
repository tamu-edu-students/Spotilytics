Feature: Require Spotify auth before accessing protected pages
  As a visitor
  I want protected pages to require Spotify login
  So that my data isn’t exposed

  Scenario: Not logged in -> redirected with alert
    Given a protected test page that requires Spotify login
    And I am not logged in
    When I visit the protected test page
    Then I should be redirected to the home page
    And I should see the login required alert

  Scenario: Logged in -> passes through (no redirect)
    Given a protected test page that requires Spotify login
    And I am logged in
    When I visit the protected test page
    Then I should see "Protected OK"
    And I should not see the login required alert