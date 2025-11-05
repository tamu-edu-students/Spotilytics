Feature: PagesController#top_tracks legacy coverage
  Background:
    Given a test endpoint that proxies to pages#top_tracks
    And I am signed in with Spotify

  Scenario: Success with invalid limit defaults to 10
    And Spotify returns N top tracks "10" for any time range
    When I visit the pages top tracks test endpoint with limit "7"
    Then I should see COUNT=10


