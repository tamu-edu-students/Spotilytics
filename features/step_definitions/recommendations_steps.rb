require 'ostruct'

module RecommendationsStub
  def recommendations_mock
    @recommendations_mock ||= instance_double(SpotifyClient)
  end

  def stub_spotify_client_with(mock)
    allow(SpotifyClient).to receive(:new).and_return(mock)
  end

  def build_artist_seeds(count)
    Array.new(count) { |i| OpenStruct.new(name: "Artist Seed #{i + 1}") }
  end

  def build_track_seeds(count)
    Array.new(count) { |i| OpenStruct.new(name: "Track Seed #{i + 1}") }
  end

  def build_recommendations(count)
    Array.new(count) do |i|
      OpenStruct.new(
        name: "Recommended Track #{i + 1}",
        artists: "Rec Artist #{i + 1}",
        album_image_url: "http://example.com/cover#{i + 1}.jpg",
        spotify_url: "http://spotify.example/#{i + 1}"
      )
    end
  end
end

World(RecommendationsStub)

Given("Spotify returns recommendation data") do
  stub_spotify_client_with(recommendations_mock)

  allow(recommendations_mock).to receive(:top_artists)
    .with(limit: 20, time_range: 'medium_term')
    .and_return(build_artist_seeds(10))

  allow(recommendations_mock).to receive(:top_tracks)
    .with(limit: 20, time_range: 'medium_term')
    .and_return(build_track_seeds(10))

  allow(recommendations_mock).to receive(:search_tracks)
    .and_return(build_recommendations(6))
end

Given("Spotify top APIs raise unauthorized for recommendations") do
  stub_spotify_client_with(recommendations_mock)

  allow(recommendations_mock).to receive(:top_artists)
    .with(limit: 20, time_range: 'medium_term')
    .and_raise(SpotifyClient::UnauthorizedError.new('expired'))
end

Given("Spotify recommendations search fails with {string}") do |message|
  stub_spotify_client_with(recommendations_mock)

  allow(recommendations_mock).to receive(:top_artists)
    .with(limit: 20, time_range: 'medium_term')
    .and_return(build_artist_seeds(10))

  allow(recommendations_mock).to receive(:top_tracks)
    .with(limit: 20, time_range: 'medium_term')
    .and_return(build_track_seeds(10))

  allow(recommendations_mock).to receive(:search_tracks)
    .and_raise(SpotifyClient::Error.new(message))
end

When("I visit the recommendations page") do
  visit recommendations_path
end

Then("I should see recommendation cards") do
  expect(page).to have_css('.card', minimum: 1)
  expect(page).to have_content('Recommended Track 1')
end

Then("I should see the recommendations error {string}") do |message|
  expect(page).to have_current_path(recommendations_path, ignore_query: true)
  expect(page).to have_content(message)
  expect(page).not_to have_css('.card')
end

Then("I should be redirected home with message {string}") do |message|
  location = page.driver.response.headers['Location']
  if location.present?
    expect(location).to include(home_path)
    visit location
  else
    expect(page).to have_current_path(home_path, ignore_query: true)
  end
  expect(page).to have_content(message)
end
