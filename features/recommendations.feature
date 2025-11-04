Feature: Recommendations
  As a Spotify user
  I want to see track recommendations
  So that I can discover new music

  Background:
    Given I am signed in with Spotify

  Scenario: View recommendations successfully
    And Spotify returns recommendation data
    When I visit the recommendations page
    Then I should see recommendation cards

  Scenario: Recommendations require login when unauthorized
    And Spotify top APIs raise unauthorized for recommendations
    When I visit the recommendations page
    Then I should be redirected home with message "You must log in with spotify to view your reccomendations."

  Scenario: Recommendations show an error when search fails
    And Spotify recommendations search fails with "service failure"
    When I visit the recommendations page
    Then I should see the recommendations error "Failed to fetch recommendations: service failure"
