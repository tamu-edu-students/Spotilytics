require "ostruct"

Given("Spotify returns top tracks with ids") do
  tracks = [
    OpenStruct.new(id: "t1", name: "Track One", artists: "Artist A"),
    OpenStruct.new(id: "t2", name: "Track Two", artists: "Artist B")
  ]

  allow_any_instance_of(SpotifyClient).to receive(:top_tracks).and_return(tracks)
end

Given("Spotify returns audio features for those tracks") do
  features = {
    "t1" => OpenStruct.new(id: "t1", energy: 0.8, valence: 0.7, danceability: 0.75, tempo: 128, acousticness: 0.2, instrumentalness: 0.1),
    "t2" => OpenStruct.new(id: "t2", energy: 0.7, valence: 0.6, danceability: 0.7, tempo: 130, acousticness: 0.15, instrumentalness: 0.05)
  }

  allow_any_instance_of(SpotifyClient).to receive(:track_audio_features).and_return(features)
  allow_any_instance_of(SpotifyClient).to receive(:recently_played).and_return([])

  plays = [
    OpenStruct.new(id: "p1", played_at: Time.current)
  ]
  allow_any_instance_of(ListeningHistory).to receive(:ingest!).with([]).and_return(nil)
  allow_any_instance_of(ListeningHistory).to receive(:recent_entries).with(limit: 300).and_return(plays)
end
