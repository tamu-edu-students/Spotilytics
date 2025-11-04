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

  Scenario: Default shows Top 10 for each time range
    Given I am signed in with Spotify
    When I go to the top artists page
    Then the "Past Year" selector should have "Top 10" selected
    And the "Past 6 Months" selector should have "Top 10" selected
    And the "Past 4 Weeks" selector should have "Top 10" selected
    And the "Past Year" column should list exactly 10 artists
    And the "Past 6 Months" column should list exactly 10 artists
    And the "Past 4 Weeks" column should list exactly 10 artists

  Scenario: Change only one time range without JavaScript
    Given I am signed in with Spotify
    And I go to the top artists page
    When I choose "Top 25" for "Past Year" and click Update
    Then the "Past Year" selector should have "Top 25" selected
    And the "Past 6 Months" selector should have "Top 10" selected
    And the "Past 4 Weeks" selector should have "Top 10" selected
    And the "Past Year" column should list exactly 25 artists
    And the "Past 6 Months" column should list exactly 10 artists
    And the "Past 4 Weeks" column should list exactly 10 artists

  Scenario: Visiting with per-range limits preselected
    Given I am signed in with Spotify
    When I visit the top artists page with limits "50" for "Past Year" and "25" for "Past 6 Months"
    Then the "Past Year" selector should have "Top 50" selected
    And the "Past 6 Months" selector should have "Top 25" selected
    And the "Past 4 Weeks" selector should have "Top 10" selected
    And the "Past Year" column should list exactly 50 artists
    And the "Past 6 Months" column should list exactly 25 artists
    And the "Past 4 Weeks" column should list exactly 10 artists

  Scenario: Top artists token expired → redirected to home with alert
    Given OmniAuth is in test mode
    And I am signed in with Spotify
    And Spotify raises Unauthorized for top artists
    When I go to the top artists page
    Then I should be on the home page
    And I should see "You must log in with spotify to view your top artists."

