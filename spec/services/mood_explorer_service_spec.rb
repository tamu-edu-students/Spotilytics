require "rails_helper"

RSpec.describe MoodExplorerService do
  let(:track1) { OpenStruct.new(id: "t1", name: "High Energy", artists: "A") }
  let(:track2) { OpenStruct.new(id: "t2", name: "Sad Song",    artists: "B") }

  let(:features) do
    [
      {
        "spotify_id"    => "t1",
        "energy"        => 0.9,
        "valence"       => 0.8,
        "danceability"  => 0.8
      },
      {
        "spotify_id"    => "t2",
        "energy"        => 0.3,
        "valence"       => 0.2,
        "danceability"  => 0.4
      }
    ]
  end

  describe ".detect_single" do
    it "classifies a hype track" do
      features_hash = {
        "energy"   => 0.8,
        "valence"  => 0.7,
        "danceability" => 0.7
      }

      mood = described_class.detect_single(features_hash)
      expect(mood).to eq(:hype)
    end

    it "returns :misc when nothing matches" do
      features_hash = { "energy" => 0.5, "valence" => 0.5, "danceability" => 0.5 }
      mood = described_class.detect_single(features_hash)
      expect(mood).to eq(:misc)
    end
  end

  describe "#clustered" do
    it "groups tracks into mood buckets using spotify_id lookup" do
      service = described_class.new([ track1, track2 ], features)
      clusters = service.clustered

      expect(clusters.values.flatten.map { |h| h[:track] }).to match_array([ track1, track2 ])

      hype_tracks = clusters[:hype].map { |h| h[:track] }
      expect(hype_tracks).to include(track1)
    end
  end
end
