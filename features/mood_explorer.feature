Feature: Songs Mood Explorer
  As a listener
  I want to see my top tracks mapped into mood clusters
  So that I can explore my listening moods

  Background:
    Given I am logged in with Spotify for the dashboard

  Scenario: See clustered songs on the Mood Explorer dashboard
    Given the Spotify API returns top tracks with mood features
    When I visit the Mood Explorer dashboard
    Then I should see the heading "Mood Explorer"
    And I should see a mood group header "Hype"
    And I should see at least one mood track card
    And the first mood track card should show energy and danceability