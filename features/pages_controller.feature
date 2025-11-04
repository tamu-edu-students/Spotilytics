Feature: PagesController edge cases
  As an authenticated Spotify user
  I want friendly behavior on errors and cache refresh
  So the app handles exceptions gracefully

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  # --- /clear ---
  Scenario: Refresh cache succeeds
    And Spotify allows clear user cache
    When I visit the clear page
    Then I should be on the home page
    And I should see "Data refreshed successfully"

  Scenario: Refresh cache raises Unauthorized → alert + redirect home
    And Spotify clear user cache raises Unauthorized
    When I visit the clear page
    Then I should be on the home page
    And I should see "You must log in with spotify to refresh your data."

  # --- /top-artists ---
  Scenario: Top Artists raises generic error → friendly message + empty lists
    And Spotify top artists raises a generic error
    When I go to the top artists page
    Then I should see "We were unable to load your top artists from Spotify. Please try again later."
    And the "Past Year" column should list exactly 0 artists
    And the "Past 6 Months" column should list exactly 0 artists
    And the "Past 4 Weeks" column should list exactly 0 artists

  # --- /view-profile ---
  Scenario: View Profile raises Unauthorized → alert + redirect home
    And Spotify profile raises Unauthorized
    When I visit the view profile page
    Then I should be on the home page
    And I should see "You must log in with spotify to view your profile."

  Scenario: View Profile raises generic error → friendly message on same page
    And Spotify profile raises a generic error
    When I visit the view profile page
    Then I should be on the view profile page
    And I should see "We were unable to load your Spotify data right now. Please try again later."
