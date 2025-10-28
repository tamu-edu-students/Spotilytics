Feature: Top Tracks page
  As a Spotify user
  I want to view my top 10 tracks for the last year
  So I can explore and play them

  Scenario: The top tracks page lists tracks with rank and Spotify link
    Given I am logged in with Spotify for the top tracks page
    And Spotify responds with ranked top tracks
    When I go to the top tracks page
    Then I should see the top tracks header
    And I should see the first track rank
    And I should see the Spotify play link
