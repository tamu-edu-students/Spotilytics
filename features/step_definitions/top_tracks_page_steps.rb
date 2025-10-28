# features/step_definitions/top_tracks_steps.rb
require 'ostruct'

#
# Test-only controller for Cucumber flows.
# This lets you bypass auth checks and still render the real view.
#
class CucumberTopTracksController < ApplicationController
  def index
    # Pretend the user is logged in so we don't redirect.
    session[:spotify_user] ||= { "id" => "fake_user_id", "name" => "Test User" }

    # Call the real Spotify client so we hit our stubs.
    client = SpotifyClient.new(session: session)

    # NOW using long_term to match dashboard and the app's behavior.
    @tracks = client.top_tracks(limit: 10, time_range: "long_term")

    @error = nil

    # Reuse the actual app view: app/views/top_tracks/index.html.erb
    render template: "top_tracks/index"
  end
end

#
# GIVEN: I am logged in with Spotify for the top tracks page
#
Given("I am logged in with Spotify for the top tracks page") do
  # no-op; CucumberTopTracksController#index seeds session[:spotify_user]
end

#
# GIVEN: Spotify responds with ranked top tracks
#
Given("Spotify responds with ranked top tracks") do
  mock_tracks = [
    OpenStruct.new(
      rank: 1,
      name: "Annual Smash",
      artists: "Big Artist",
      album_name: "Big Album",
      album_image_url: "http://img/big.jpg",
      popularity: 97,
      preview_url: nil,
      spotify_url: "https://open.spotify.com/track/abc123"
    ),
    OpenStruct.new(
      rank: 2,
      name: "Second Favorite",
      artists: "Other Artist",
      album_name: "Other Album",
      album_image_url: "http://img/other.jpg",
      popularity: 88,
      preview_url: "http://preview.mp3",
      spotify_url: "https://open.spotify.com/track/def456"
    )
  ]

  mock_client = double("SpotifyClient")

  # allow SpotifyClient.new(session: ...) to return our mock client
  allow(SpotifyClient).to receive(:new).and_return(mock_client)

  # now the app under test will call top_tracks(limit: 10, time_range: "long_term")
  allow(mock_client).to receive(:top_tracks).and_return(mock_tracks)

  @mock_tracks = mock_tracks
end

#
# WHEN: I go to the top tracks page
#
When("I go to the top tracks page") do
  Rails.application.routes.draw do
    # Cucumber-only test route
    get "/cucumber_top_tracks", to: "cucumber_top_tracks#index"

    # App routes needed for layout/partials to render without blowing up
    get '/dashboard', to: 'pages#dashboard'
    get '/home', to: 'pages#home'
    root 'pages#home'

    match '/auth/spotify/callback', to: 'sessions#create', via: %i[get post]
    get    '/auth/failure',         to: "sessions#failure"
    get    '/login',                to: redirect("/auth/spotify"), as: :login
    delete '/logout', to: 'sessions#destroy', as: :logout

    # keep original /top_tracks route definition for completeness
    get "/top_tracks", to: "top_tracks#index", as: :top_tracks
  end

  visit "/cucumber_top_tracks"
end

#
# THEN steps (assertions)
#

Then('I should see "Your Top Tracks (Past 1 year)"') do
  expect(page).to have_content("Your Top Tracks (Past 1 year)")
end

Then('I should see "#1"') do
  expect(page).to have_content("#1")
end

Then('I should see "Play on Spotify"') do
  expect(page).to have_content("Play on Spotify")
end

Then("I should see the top tracks header") do
  expect(page).to have_content("Your Top Tracks (Past 1 year)")
end

Then("I should see the first track rank") do
  expect(page).to have_content("#1")
end

Then("I should see the Spotify play link") do
  expect(page).to have_content("Play on Spotify")
end
