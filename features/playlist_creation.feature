Feature: Create a Spotify playlist from my top tracks
  As a logged-in Spotify user
  I want to create a playlist from my top tracks for a chosen time range
  So I can save and listen to them easily

  Background:
    # This just ensures routes render somewhere after redirects
    Given I am on the home page

  Scenario: Not logged in → redirected to root with alert
    When I POST create_playlist for "long_term" without login
    Then I should be on the home page
    And I should see "Please sign in with Spotify first."

  Scenario: Invalid time range → redirected to top tracks with alert
    Given I am logged in for playlists
    When I POST create_playlist for "invalid_range"
    Then I should be on the Top Tracks page
    And I should see "Invalid time range."

  Scenario: Spotify unauthorized → redirect to root with alert
    Given I am logged in for playlists
    And Spotify raises Unauthorized on any call
    When I POST create_playlist for "long_term"
    Then I should be on the home page
    And I should see "Session expired. Please sign in with Spotify again."

  Scenario: Spotify generic error → redirect to top tracks with alert
    Given I am logged in for playlists
    And Spotify raises Error on any call
    When I POST create_playlist for "long_term"
    Then I should be on the Top Tracks page
    And I should see "Couldn't create playlist on Spotify."