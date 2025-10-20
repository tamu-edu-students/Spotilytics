Feature: Top artists
  As an authenticated Spotify user
  I want to view my top 10 artists for the year to date
  So I can see who I've listened to the most

  Background:
    Given I am an authenticated user with spotify data

  Scenario: View top 10 artists
    When I visit the top artists page
    Then I should see a list of 10 artists
    And the artists should be ordered by play count descending

