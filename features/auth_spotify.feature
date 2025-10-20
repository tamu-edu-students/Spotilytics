Feature: Spotify sign in/out
  As a visitor
  I want to sign in with Spotify
  So that I can see my stats and sign out

  Background:
    Given OmniAuth is in test mode

  Scenario: Successful Spotify sign-in
    Given I am on the home page
    When I click "Sign in with Spotify"
    Then I should be on the home page
    And I should see "Signed in with Spotify"
    And I should see "Test User"
    And I should see "Log out"

  Scenario: Sign out
    Given I am signed in with Spotify
    When I click "Log out"
    Then I should be on the home page
    And I should see "Signed out"
    And I should see "Sign in with Spotify"

  Scenario: Failed Spotify sign-in
    Given OmniAuth will return "developer access not configured"
    When I visit "/auth/failure?message=developer_access_not_configured"
    Then I should be on the home page
    And I should see "Spotify login failed"