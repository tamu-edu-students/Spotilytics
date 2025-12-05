require "ostruct"

Given("the playlist energy service returns sample points") do
  mock_service = instance_double(PlaylistEnergyService)
  allow(PlaylistEnergyService).to receive(:new).and_return(mock_service)

  allow(mock_service).to receive(:energy_profile).and_return([
    { label: "1. Track Alpha", energy: 75.0, track: OpenStruct.new(name: "Track Alpha", artists: "A") },
    { label: "2. Track Beta", energy: 42.5, track: OpenStruct.new(name: "Track Beta", artists: "B") }
  ])
end

Given("Spotify playlist tracks and features are available") do
  tracks = [
    OpenStruct.new(id: "t1", name: "One", artists: "A"),
    OpenStruct.new(id: "t2", name: "Two", artists: "B"),
    OpenStruct.new(id: "t3", name: "Three", artists: "C")
  ]

  allow_any_instance_of(SpotifyClient)
    .to receive(:playlist_tracks)
    .with(playlist_id: "pl-energy", limit: 100)
    .and_return(tracks)

  allow(ReccoBeatsClient)
    .to receive(:fetch_audio_features)
    .with([ "t1", "t2", "t3" ])
    .and_return([
      { "id" => "t1", "energy" => 0.5 },   # 50.0%
      { "id" => "t2", "energy" => 150 },   # capped to 100%
      { "id" => "t3", "energy" => nil }    # N/A
    ])
end
