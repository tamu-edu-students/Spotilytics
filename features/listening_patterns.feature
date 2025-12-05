Feature: Listening Pattern page
  As a listener
  I want to see when I listen by hour
  So I can understand my habits

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  Scenario: Viewing the hourly histogram with recent plays
    Given Spotify returns 3 recent plays across hours
    When I visit "/listening-patterns"
    Then I should see "Plays analyzed"
    And I should see "last 3 plays happened"
    And I should see "Listens by hour"
