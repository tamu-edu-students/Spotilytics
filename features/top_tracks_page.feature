Feature: Top Tracks page
  As a Spotify user
  I want to view my top 10 tracks for the last year
  So I can explore and play them

  Background:
    Given I am logged in with Spotify for the top tracks page
    And Spotify responds dynamically with N top tracks based on the requested limit

  Scenario: The top tracks page lists tracks with rank and Spotify link
    Given I am logged in with Spotify for the top tracks page
    And Spotify responds with ranked top tracks
    When I go to the top tracks page
    Then I should see the top tracks header
    And I should see the first track rank
    And I should see the Spotify play link

  Scenario: Default selection shows Top 10
    When I go to the top tracks page
    Then the limit selector should have "Top 10" selected
    And I should see exactly 10 tracks

  Scenario: Select Top 25 without JavaScript (click Update)
    When I go to the top tracks page
    And I choose "Top 25" in the limit selector and click Update
    Then the limit selector should have "Top 25" selected
    And I should see exactly 25 tracks

  Scenario: Visiting with limit parameter preselects option
    When I go to the top tracks page
    And I search for top tracks with limit "50"
    Then the limit selector should have "Top 50" selected
    And I should see exactly 50 tracks
