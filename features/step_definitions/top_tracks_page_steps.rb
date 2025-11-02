# features/step_definitions/top_tracks_steps.rb
require 'ostruct'
require "addressable/uri"
require "rack/utils"

def range_label_to_key(label)
  {
    "Past Year"      => "long_term",
    "Past 6 Months"  => "medium_term",
    "Past 4 Weeks"   => "short_term"
  }.fetch(label)
end

#
# Test-only controller for Cucumber flows.
# This lets you bypass auth checks and still render the real view.
#
class CucumberTopTracksController < ApplicationController
  def index
    session[:spotify_user] ||= { "id" => "fake_user_id", "name" => "Test User" }

    client = SpotifyClient.new(session: session)

    limit = params[:limit].to_i
    limit = 10 unless [10, 25, 50].include?(limit)

    @tracks = client.top_tracks(limit: limit, time_range: "long_term")

    @error = nil

    render template: "top_tracks/index"
  end
end

#
# GIVEN: I am logged in with Spotify for the top tracks page
#
Given('I am logged in with Spotify for the top tracks page') do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
    provider: 'spotify',
    uid:      'user_123',
    info:     { name: 'Test User', email: 'test@example.com', image: nil },
    credentials: {
      token:         'fake_token',
      refresh_token: 'fake_refresh',
      expires_at:    1.hour.from_now.to_i
    }
  )

  visit '/auth/spotify'
  visit '/auth/spotify/callback'
end

#
# GIVEN: Spotify responds with ranked top tracks
#
Given('Spotify responds with ranked top tracks') do
  tracks = (1..10).map do |i|
    OpenStruct.new(
      id: "t#{i}",
      rank: i,
      name: "Song #{i}",
      artists: "Artist #{i}",
      album_name: "Album #{i}",
      album_image_url: "http://img/#{i}.jpg",
      popularity: 100 - i,
      preview_url: nil,
      spotify_url: "https://open.spotify.com/track/#{i}"
    )
  end

  mock = instance_double(SpotifyClient)

  allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock)

  %w[short_term medium_term long_term].each do |range|
    allow(mock).to receive(:top_tracks)
      .with(limit: anything, time_range: range)
      .and_return(tracks)
  end
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
When('I go to the top tracks page') do
  visit top_tracks_path
end

When('I choose {string} in the limit selector for {string} and click Update') do |label, range_label|
  key = range_label_to_key(range_label)

  other_keys = %w[short_term medium_term long_term] - [key]
  preserved  = {}

  within(%Q{.time-header-col[data-range="#{key}"]}) do
    other_keys.each do |k|
      preserved[k] = find(%Q{input[name="limit_#{k}"]}, visible: :all).value.to_s
    end

    select(label, from: "limit_#{key}")
    if has_selector?('button.js-hidden[type="submit"]', visible: :all)
      find('button.js-hidden[type="submit"]', visible: :all).click
    else
      first('button[type="submit"],input[type="submit"]', minimum: 1, visible: :all).click
    end
  end

  uri    = Addressable::URI.parse(current_url)
  expect(uri.path).to eq("/top_tracks")

  q      = Rack::Utils.parse_nested_query(uri.query || "")
  expect(q["limit_#{key}"]).to eq(label[/\d+/])     # "25", "50", etc.
  expect(q["limit_#{other_keys[0]}"]).to eq(preserved[other_keys[0]])
  expect(q["limit_#{other_keys[1]}"]).to eq(preserved[other_keys[1]])
end

When("I choose {string} in the limit selector \(auto submit\)") do |label|
  visit "/cucumber_top_tracks"
  select label, from: "limit"
end

When("I search for top tracks with limit {string}") do |val|
  n = val[/\d+/].to_i 

  visit top_tracks_path(
    limit_short_term:  n,
    limit_medium_term: n,
    limit_long_term:   n
  )

  @last_changed_key = 'long_term'
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

Then('I should see the top tracks header') do
  expect(page).to have_css('h1,h5', text: /Your Top Tracks/i)

  expect(page).to have_text(/Short term \(4 weeks\) .* Medium \(6 months\) .* Long \(1 year\)/i)
end

Then("I should see the first track rank") do
  expect(page).to have_content("#1")
end

Then("I should see the Spotify play link") do
  expect(page).to have_content("Play on Spotify")
end

Then('the limit selector should have {string} selected') do |label|
  possible_ids = ['limit_short_term', 'limit_medium_term', 'limit_long_term']

  found = possible_ids.any? do |id|
    page.has_select?(id, selected: label)
  end

  expect(found).to be_truthy, "Expected one of #{possible_ids.join(', ')} to have '#{label}' selected"
end

Then('I should see exactly {int} tracks') do |n|
  expect(page).to have_css('.tracks-grid-row', minimum: 10)

  long_col_cells = page.all(:xpath,
    "//div[contains(@class,'tracks-grid-row')]" \
    "/div[contains(@class,'tracks-col')][3]" \
    "//div[contains(@class,'track-lineup')]"
  )
  expect(long_col_cells.size).to eq(n)
end


