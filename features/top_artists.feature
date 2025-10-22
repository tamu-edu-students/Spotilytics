Feature: Top artists
  As an authenticated Spotify user
  I want to view my top 10 artists for approximately year from date
  So I can see who I've listened to the most

  Background:
    Given I am an authenticated user with spotify data

  Scenario: View top 10 artists on dashboard
    When I visit the dashboard page
    Then I should see either a top-artist list or a top-artist placeholder
    And if a list exists the artists should be ordered by play count descending

