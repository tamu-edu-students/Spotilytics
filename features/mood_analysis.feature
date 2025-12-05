Feature: Mood Analysis (server-side)
  As a listener
  I want to see mood analysis for a specific top track
  So that I understand why it belongs to a mood cluster

  Background:
    Given I am logged in with Spotify for the dashboard

  Scenario: View mood analysis for a valid top track
    Given the Spotify API returns top tracks with mood features
    And I pick the first top track for testing
    When I visit the mood analysis page for that track
    Then I should see "Mood Explorer"
    And I should see the name of the track
    And I should see "Feature Breakdown"
    And I should see an energy value
    And I should see a tempo value in BPM