# features/step_definitions/pages_steps.rb
require 'ostruct'

def pages_mock_spotify!
  @pages_mock_spotify ||= instance_double(SpotifyClient)
  allow(SpotifyClient).to receive(:new).with(session: anything).and_return(@pages_mock_spotify)
  @pages_mock_spotify
end

# -------- CLEAR (/clear) --------

Given("Spotify allows clear user cache") do
  mock = pages_mock_spotify!
  allow(mock).to receive(:clear_user_cache).and_return(true)
end

Given("Spotify clear user cache raises Unauthorized") do
  mock = pages_mock_spotify!
  allow(mock).to receive(:clear_user_cache).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
end

When("I visit the clear page") do
  visit Rails.application.routes.url_helpers.clear_path
end

# -------- TOP ARTISTS (/top-artists) --------

Given("Spotify top artists raises a generic error") do
  mock = pages_mock_spotify!
  # pages#top_artists calls these methods for all 3 ranges; we make any call blow up
  allow(mock).to receive(:top_artists).and_raise(SpotifyClient::Error.new("rate limited"))
  # Dashboard/top-artists page might also read these occasionally; keep them harmless
  allow(mock).to receive(:followed_artists).and_return([])
  allow(mock).to receive(:new_releases).and_return([])
end

# -------- VIEW PROFILE (/view-profile) --------

Given("Spotify profile raises Unauthorized") do
  mock = pages_mock_spotify!
  allow(mock).to receive(:profile).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
end

Given("Spotify profile raises a generic error") do
  mock = pages_mock_spotify!
  allow(mock).to receive(:profile).and_raise(SpotifyClient::Error.new("rate limited"))
end

When("I visit the view profile page") do
  visit Rails.application.routes.url_helpers.view_profile_path
end

Then("I should be on the view profile page") do
  expect(page).to have_current_path(Rails.application.routes.url_helpers.view_profile_path, ignore_query: true)
end

Then("I should be on the pages top tracks test endpoint with friendly message") do
  expect(page).to have_current_path(/cuke_pages_top_tracks/)
  expect(page).to have_content("We were unable to load your top tracks from Spotify. Please try again later.")
end
