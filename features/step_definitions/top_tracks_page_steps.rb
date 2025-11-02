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

    # accept ?limit=10/25/50 (default 10)
    limit = params[:limit].to_i
    limit = 10 unless [10, 25, 50].include?(limit)

    # NOW using long_term to match dashboard and the app's behavior.
    @tracks = client.top_tracks(limit: limit, time_range: "long_term")

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
  mock_tracks = (1..10).map do |i|
    OpenStruct.new(
      rank: i,
      name: "Annual Smash #{i}",
      artists: "Artist #{i}",
      album_name: "Album #{i}",
      album_image_url: "http://img/#{i}.jpg",
      popularity: 70 + (i % 30),
      preview_url: nil,
      spotify_url: "https://open.spotify.com/track/#{i}"
    )
  end

  mock_client = double("SpotifyClient")

  # allow SpotifyClient.new(session: ...) to return our mock client
  allow(SpotifyClient).to receive(:new).and_return(mock_client)

  # now the app under test will call top_tracks(limit: 10, time_range: "long_term")
  allow(mock_client).to receive(:top_tracks).and_return(mock_tracks)

  @mock_tracks = mock_tracks
end

Given("Spotify responds dynamically with N top tracks based on the requested limit") do
  mock_client = double("SpotifyClient")
  allow(SpotifyClient).to receive(:new).and_return(mock_client)

  allow(mock_client).to receive(:top_tracks) do |args|
    n = (args[:limit] || 10).to_i
    (1..n).map do |i|
      OpenStruct.new(
        rank: i,
        name: "Song #{i}",
        artists: "Artist #{i}",
        album_name: "Album #{i}",
        album_image_url: nil,
        popularity: 50 + (i % 50),
        preview_url: nil,
        spotify_url: "https://open.spotify.com/track/#{i}"
      )
    end
  end
end

#
# WHEN: I go to the top tracks page
#
When("I go to the top tracks page") do
  Rails.application.routes.draw do
    # Cucumber-only test route
    get "/cucumber_top_tracks", to: "cucumber_top_tracks#index"

    get "/top_tracks",  to: "cucumber_top_tracks#index", as: :top_tracks
    get "/top_artists", to: "cucumber_top_tracks#index", as: :top_artists

    get  "/home",      to: "pages#home",      as: :home
    get  "/dashboard", to: "pages#dashboard", as: :dashboard

    match "/login",  to: redirect("/"), via: [:get, :post],                 as: :login
    match "/logout", to: redirect("/"), via: [:get, :post, :delete],        as: :logout
    match "/auth/spotify/callback", to: redirect("/"), via: [:get, :post]
    get   "/auth/failure", to: redirect("/")

    root "pages#home"
  end

  visit "/cucumber_top_tracks"
end

When("I choose {string} in the limit selector and click Update") do |label|
  within('form[action*="/top_tracks"]') do
    select label, from: "limit"
    click_button "Update"
  end

  expected = label[/\d+/].to_i

  # Ensure we navigated to /top_tracks with ?limit=<expected>
  expect(page).to have_current_path(
    %r{\A/top_tracks\?(?:[^#]*&)?limit=#{expected}(?:&[^#]*)?\z},
    ignore_query: false
  )
end

# JS path: onchange auto-submits (use @javascript tag on the scenario)
When("I choose {string} in the limit selector \(auto submit\)") do |label|
  visit "/cucumber_top_tracks"
  select label, from: "limit"
end

When("I search for top tracks with limit {string}") do |val|
  visit top_tracks_path(limit: val)
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

Then("the limit selector should have {string} selected") do |label|
  expect(page).to have_select("limit", selected: label)
end

Then("I should see exactly {int} tracks") do |n|
  # Each row has class .top-track in your view
  expect(page.all(".top-track").size).to eq(n)
  # optional: last rank badge appears somewhere
  expect(page).to have_content("##{n}")
end
