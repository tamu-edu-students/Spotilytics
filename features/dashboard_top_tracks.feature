Feature: Dashboard shows top tracks
  As a Spotify user
  I want to see my top tracks on the dashboard
  So I can quickly check my top songs for the year

  Scenario: Dashboard renders the Top Tracks card and primary track
    Given I am logged in with Spotify for the dashboard
    And Spotify responds with top tracks for the dashboard
    When I go to the dashboard
    Then I should see the Top Tracks card
    And I should see the dashboard primary track name
    And I should see the dashboard primary track artist
    And I should see the dashboard CTA to view top tracks

  Scenario: Spotify token expired -> redirect to home with re-auth alert
    Given I am logged in with Spotify for the dashboard
    And Spotify for the dashboard raises Unauthorized
    When I go to the dashboard
    Then I should be on the home page
    And I should see "You must log in with spotify to access the dashboard."

  Scenario: Generic Spotify error -> dashboard renders 200 with friendly message
    Given I am logged in with Spotify for the dashboard
    And Spotify for the dashboard raises a generic error
    When I go to the dashboard
    Then I should be on the dashboard page
    And I should see "We were unable to load your Spotify data right now. Please try again later."


