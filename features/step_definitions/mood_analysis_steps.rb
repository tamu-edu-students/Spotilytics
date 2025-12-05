Given("there is at least one top track in my account") do
  step "I am logged in with a stubbed Spotify user"
  @top_track = OpenStruct.new(
    id:      "test-track-1",
    name:    "Test Song",
    artists: "Test Artist",
    image:   "https://example.com/test-cover.jpg"
  )

  allow_any_instance_of(SpotifyClient)
    .to receive(:top_tracks_1)
    .and_return([ @top_track ])

  allow(ReccoBeatsClient).to receive(:fetch_audio_features)
    .with([ "test-track-1" ])
    .and_return([ {
      "spotify_id"    => "test-track-1",
      "energy"        => 0.81,
      "danceability"  => 0.72,
      "valence"       => 0.64,
      "acousticness"  => 0.12,
      "tempo"         => 123.0
    } ])
end

Then("I should see the name of the track") do
  expect(page).to have_css(".ma-title")
end

Then("I should see a tempo in BPM") do
  expect(page).to have_text("BPM")
end
