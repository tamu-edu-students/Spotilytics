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

  Scenario: Successful playlist creation (session already has user id)
    Given I am logged in for playlists with user id "user_123"
    And Spotify returns 10 top tracks for "long_term"
    And Spotify creates playlist "Your Top Tracks - Last 1 Year" and adds tracks
    When I POST create_playlist for "long_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 1 Year"

  Scenario: Successful playlist creation (user id fetched from Spotify API)
    Given I am logged in for playlists without user id
    And Spotify API returns user id "api_user_9"
    And Spotify returns 10 top tracks for "long_term"
    And Spotify creates playlist "Your Top Tracks - Last 1 Year" and adds tracks
    When I POST create_playlist for "long_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 1 Year"

  Scenario: No tracks available → redirected to Top Tracks with alert
    Given I am logged in for playlists
    And Spotify returns 0 top tracks for "long_term"
    When I POST create_playlist for "long_term"
    Then I should be on the Top Tracks page
    And I should see "No tracks available for Last 1 Year."

  # Extra happy-paths to cover the medium/short labels in VALID_RANGES
  Scenario: Successful playlist creation for medium_term (Last 6 Months)
    Given I am logged in for playlists with user id "user_123"
    And Spotify returns 10 top tracks for "medium_term"
    And Spotify creates playlist "Your Top Tracks - Last 6 Months" and adds tracks
    When I POST create_playlist for "medium_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 6 Months"

  Scenario: Successful playlist creation for short_term (Last 4 Weeks)
    Given I am logged in for playlists with user id "user_123"
    And Spotify returns 10 top tracks for "short_term"
    And Spotify creates playlist "Your Top Tracks - Last 4 Weeks" and adds tracks
    When I POST create_playlist for "short_term"
    Then I should be on the Top Tracks page
    And I should see "Playlist created on Spotify: Your Top Tracks - Last 4 Weeks"
