require "rails_helper"

RSpec.describe ReccoBeatsClient do
  describe ".fetch_audio_features" do
    it "returns [] when ids are blank" do
      expect(described_class.fetch_audio_features([])).to eq([])
    end

    it "parses content and adds spotify_id derived from href" do
      fake_body = {
        "content" => [
          {
            "id"          => "abc",
            "href"        => "https://open.spotify.com/track/track123",
            "energy"      => 0.9,
            "valence"     => 0.7,
            "danceability"=> 0.8
          }
        ]
      }.to_json

      fake_response = instance_double(
        Net::HTTPOK,
        is_a?: true,
        body: fake_body,
        code: "200"
      )

      allow(Net::HTTP).to receive(:get_response).and_return(fake_response)

      result = described_class.fetch_audio_features([ "track123" ])
      expect(result.size).to eq(1)
      expect(result.first["spotify_id"]).to eq("track123")
      expect(result.first["energy"]).to eq(0.9)
    end

    it "logs and returns [] on non-success" do
      fake_response = instance_double(
        Net::HTTPBadRequest,
        is_a?: false,
        body: "error",
        code: "400"
      )

      allow(Net::HTTP).to receive(:get_response).and_return(fake_response)

      expect(Rails.logger).to receive(:error).with(/ReccoBeats/)
      expect(described_class.fetch_audio_features([ "x" ])).to eq([])
    end
  end
end
