Feature: Listening heatmap page
  As a listener
  I want to see a calendar heatmap of my recent plays
  So I can visualize my listening patterns

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  Scenario: Viewing the heatmap with recent plays
    Given Spotify returns 3 recent plays across days
    When I visit "/listening-heatmap"
    Then I should see "Calendar heatmap"
    And I should see "Plays captured"
