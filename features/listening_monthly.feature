Feature: Monthly listening insights
  As a listener
  I want to see hours spent by month
  So I can track how my listening changes over time

  Background:
    Given OmniAuth is in test mode
    And I am signed in with Spotify

  Scenario: Viewing monthly listening chart with previous month summary
    Given Spotify returns recent plays across two months
    When I visit "/listening-monthly"
    Then I should see "Hours you've spent by month"
    And I should see "Previous month"
    And I should see "Jan 2025"
    And I should see "Dec 2024"
