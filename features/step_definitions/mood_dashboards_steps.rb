Given("the Spotify API returns top tracks with mood features") do
  @top_tracks = [
    OpenStruct.new(
      id:      "track-1",
      name:    "Sports car",
      artists: "Tate McRae",
      image:   "https://example.com/cover-1.jpg"
    ),
    OpenStruct.new(
      id:      "track-2",
      name:    "Manasaa",
      artists: "A.R. Rahman",
      image:   "https://example.com/cover-2.jpg"
    ),
    OpenStruct.new(
      id:      "track-3",
      name:    "Chill Vibes",
      artists: "Lo-Fi Beats",
      image:   "https://example.com/cover-3.jpg"
    )
  ]

  allow_any_instance_of(SpotifyClient)
    .to receive(:top_tracks_1)
    .and_return(@top_tracks)


  @feature_map = {
    "track-1" => {
      "spotify_id"    => "track-1",
      "energy"        => 0.81,
      "danceability"  => 0.75,
      "valence"       => 0.66,
      "acousticness"  => 0.10,
      "tempo"         => 124.0
    },
    "track-2" => {
      "spotify_id"    => "track-2",
      "energy"        => 0.40,
      "danceability"  => 0.60,
      "valence"       => 0.72,
      "acousticness"  => 0.35,
      "tempo"         => 92.0
    },
    "track-3" => {
      "spotify_id"    => "track-3",
      "energy"        => 0.45,
      "danceability"  => 0.55,
      "valence"       => 0.25,
      "acousticness"  => 0.15,
      "tempo"         => 78.0
    }
  }

  allow(ReccoBeatsClient).to receive(:fetch_audio_features) do |ids|
    Array(ids).map { |id| @feature_map.fetch(id) }
  end
end

Given("I pick the first top track for testing") do
  @test_track = @top_tracks.first || raise("No top tracks stubbed")
end

When("I visit the Mood Explorer dashboard") do
  visit mood_explorer_path
end

Then("I should see the heading {string}") do |heading|
  expect(page).to have_css("h1, h2", text: heading)
end

Then("I should see a mood group header {string}") do |group_name|
  expect(page).to have_css(".mood-group-title", text: group_name)
end

Then("I should see at least one mood track card") do
  expect(page).to have_css(".mood-track-card", minimum: 1)
end

Then("the first mood track card should show energy and danceability") do
  within first(".mood-track-card") do
    expect(page).to have_css(".feature-dot", text: /Energy/i)
    expect(page).to have_css(".feature-dot", text: /Danceability/i)
  end
end

When("I visit the mood analysis page for that track") do
  track = @test_track || raise("No test track chosen – did you call the Given step?")
  visit mood_analysis_path(track.id)
end

Then("I should see the track name") do
  track = @test_track || @top_tracks&.first
  expect(page).to have_content(track.name)
end

Then("I should see an energy value") do
  expect(page).to have_content("Energy")
  expect(page).to have_content(/\d\.\d{3}/)
end

Then("I should see a tempo value in BPM") do
  expect(page).to have_content("Tempo")
  expect(page).to have_content("BPM")
end
