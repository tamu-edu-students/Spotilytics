Feature: Playlist energy rollercoaster
  As a listener
  I want to see the energy curve of a playlist
  So I can understand its pacing

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  Scenario: Viewing the playlist energy graph
    Given the playlist energy service returns sample points
    When I visit "/playlists/pl123/energy"
    Then I should see "Energy Rollercoaster"
    And I should see "Playlist ID: pl123"
    And I should see "Track Alpha"
    And I should see "Track Beta"
    And I should see "Energy by track"
    And I should see "75.0%"

  Scenario: Viewing playlist energy with normalized values
    Given Spotify playlist tracks and features are available
    When I visit "/playlists/pl-energy/energy"
    Then I should see "Energy Rollercoaster"
    And I should see "Playlist ID: pl-energy"
    And I should see "50.0%"
    And I should see "100%"
    And I should see "N/A"
