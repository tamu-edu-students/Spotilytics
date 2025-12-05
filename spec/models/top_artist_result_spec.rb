require "rails_helper"

RSpec.describe TopArtistResult, type: :model do
  describe "associations" do
    it "belongs to a top_artist_batch" do
      assoc = described_class.reflect_on_association(:top_artist_batch)

      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "basic persistence" do
    it "persists correctly with a batch and attributes" do
      batch = TopArtistBatch.create!(
        spotify_user_id: "user123",
        time_range:      "long_term",
        limit:           10,
        fetched_at:      Time.current
      )

      result = described_class.create!(
        top_artist_batch: batch,
        spotify_id:       "artist1",
        name:             "Artist 1",
        image_url:        "http://img.example/artist1.jpg",
        popularity:       95,
        position:         1
      )

      result.reload
      expect(result.top_artist_batch).to eq(batch)
      expect(result.spotify_id).to eq("artist1")
      expect(result.name).to eq("Artist 1")
      expect(result.position).to eq(1)
    end
  end
end
