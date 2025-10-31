Feature: Top artists
  As an authenticated Spotify user
  I want to view my top 10 artists for approximately year from date
  So I can see who I've listened to the most

  Background:
    Given OmniAuth is in test mode
    And Spotify returns top artists data

  Scenario: View top 10 artists on dashboard
    Given I am signed in with Spotify
    When I visit the dashboard page
    Then I should see either a top-artist list or a top-artist placeholder
    And if a list exists the artists should be ordered by play count descending

  Scenario: Navigate from dashboard to full top artists page
    Given I am signed in with Spotify
    When I visit the dashboard page
    And I click the View Top Artists button
    Then I should be on the top artists page
    And I should see top-artist columns for each time range
    And Spotify should be asked for my top artists across all ranges
