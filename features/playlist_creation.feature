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

  Scenario: Success with session user id present → playlist created and tracks added
    Given I am logged in for playlists with user id "user_123"
    And Spotify returns 3 top tracks for "long_term"
    And Spotify creates playlist "Your Top Tracks - Last 1 Year" and adds tracks
    When I POST create_playlist for "long_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 1 Year"

  Scenario: Success with missing user id in session → fallback to /me
    Given I am logged in for playlists without user id
    And Spotify API returns user id "me_999"
    And Spotify returns 2 top tracks for "medium_term"
    And Spotify creates playlist "Your Top Tracks - Last 6 Months" and adds tracks
    When I POST create_playlist for "medium_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 6 Months"

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