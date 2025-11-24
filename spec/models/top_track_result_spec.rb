require "rails_helper"

RSpec.describe TopTrackResult, type: :model do
  describe "associations" do
    it "belongs to top_track_batch" do
      assoc = described_class.reflect_on_association(:top_track_batch)

      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "basic persistence" do
    it "persists correctly with attributes and batch" do
      batch = TopTrackBatch.create!(
        spotify_user_id: "user123",
        time_range:      "short_term",
        limit:           10,
        fetched_at:      Time.current
      )

      result = described_class.create!(
        top_track_batch: batch,
        spotify_id:      "track123",
        name:            "My Track",
        album_name:      "Album X",
        position:        1
      )

      result.reload

      expect(result.top_track_batch).to eq(batch)
      expect(result.spotify_id).to eq("track123")
      expect(result.name).to eq("My Track")
      expect(result.album_name).to eq("Album X")
      expect(result.position).to eq(1)
    end
  end
end