Feature: Music Personality page
  As a listener
  I want a rule-based music personality summary
  So I can see a fun description without AI

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  Scenario: Viewing my personality summary
    Given Spotify returns top tracks with ids
    And Spotify returns audio features for those tracks
    When I visit "/personality"
    Then I should see "Music personality"
    And I should see "Tracks analyzed"
