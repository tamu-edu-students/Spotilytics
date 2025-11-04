Feature: PagesController#top_tracks legacy coverage
  Background:
    Given a test endpoint that proxies to pages#top_tracks
    And I am signed in with Spotify

  Scenario: Success with invalid limit defaults to 10
    And Spotify returns N top tracks "10" for any time range
    When I visit the pages top tracks test endpoint with limit "7"
    Then I should see COUNT=10

  Scenario: Unauthorized -> redirect home
    And Spotify top tracks raises Unauthorized (pages)
    When I visit the pages top tracks test endpoint with limit "25"
    Then I should be on the home page
    And I should see "You must log in with spotify to view your top tracks."

  Scenario: Generic error -> friendly message and empty list
    And Spotify top tracks raises a generic error (pages)
    When I visit the pages top tracks test endpoint with limit "50"
    Then I should be on the pages top tracks test endpoint with friendly message

Scenario: Unauthorized -> redirect home
  And Spotify top tracks raises Unauthorized (pages)
  When I visit the pages top tracks test endpoint with limit "25"
  Then I should be on the home page
  And I should see "You must log in with spotify to view your top tracks."

Scenario: Generic error -> friendly message and empty list
  And Spotify top tracks raises a generic error (pages)
  When I visit the pages top tracks test endpoint with limit "50"
  Then I should be on the pages top tracks test endpoint with friendly message
