require "rails_helper"

RSpec.describe PlaylistEnergyService do
  let(:client) { instance_double(SpotifyClient) }
  let(:features_client) { class_double(ReccoBeatsClient) }
  let(:service) { described_class.new(client: client, features_client: features_client) }

  describe "#energy_profile" do
    it "returns tracks in playlist order with energy percentages" do
      tracks = [
        OpenStruct.new(id: "t1", name: "One", artists: "A"),
        OpenStruct.new(id: "t2", name: "Two", artists: "B")
      ]
      features = [
        { "spotify_id" => "t1", "energy" => 0.8 },
        { "spotify_id" => "t2", "energy" => 60 }
      ]

      expect(client).to receive(:playlist_tracks).with(playlist_id: "pl1", limit: 100).and_return(tracks)
      expect(features_client).to receive(:fetch_audio_features).with([ "t1", "t2" ]).and_return(features)

      result = service.energy_profile(playlist_id: "pl1")

      expect(result.map { |r| r[:track].id }).to eq([ "t1", "t2" ])
      expect(result.map { |r| r[:energy] }).to eq([ 80.0, 60.0 ])
      expect(result.first[:label]).to eq("1. One")
    end

    it "handles missing features gracefully" do
      tracks = [ OpenStruct.new(id: "t1", name: "One", artists: "A") ]

      expect(client).to receive(:playlist_tracks).and_return(tracks)
      expect(features_client).to receive(:fetch_audio_features).and_return([])

      result = service.energy_profile(playlist_id: "pl1")

      expect(result.first[:energy]).to be_nil
    end

    it "returns empty array for empty playlists" do
      expect(client).to receive(:playlist_tracks).and_return([])

      expect(service.energy_profile(playlist_id: "pl1")).to eq([])
    end
  end
end
