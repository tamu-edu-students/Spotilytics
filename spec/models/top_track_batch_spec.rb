require "rails_helper"

RSpec.describe TopTrackBatch, type: :model do
  describe "associations" do
    it "has many top_track_results with dependent: :destroy" do
      assoc = described_class.reflect_on_association(:top_track_results)

      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:has_many)
      expect(assoc.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "is valid with all required attributes" do
      batch = described_class.new(
        spotify_user_id: "user123",
        time_range:      "medium_term",
        limit:           20,
        fetched_at:      Time.current
      )

      expect(batch).to be_valid
    end

    it "is invalid without spotify_user_id" do
      batch = described_class.new(
        spotify_user_id: nil,
        time_range:      "medium_term",
        limit:           20,
        fetched_at:      Time.current
      )

      expect(batch).not_to be_valid
      expect(batch.errors[:spotify_user_id]).to be_present
    end

    it "is invalid without time_range" do
      batch = described_class.new(
        spotify_user_id: "user123",
        time_range:      nil,
        limit:           20,
        fetched_at:      Time.current
      )

      expect(batch).not_to be_valid
      expect(batch.errors[:time_range]).to be_present
    end

    it "is invalid without limit" do
      batch = described_class.new(
        spotify_user_id: "user123",
        time_range:      "medium_term",
        limit:           nil,
        fetched_at:      Time.current
      )

      expect(batch).not_to be_valid
      expect(batch.errors[:limit]).to be_present
    end

    it "is invalid without fetched_at" do
      batch = described_class.new(
        spotify_user_id: "user123",
        time_range:      "medium_term",
        limit:           20,
        fetched_at:      nil
      )

      expect(batch).not_to be_valid
      expect(batch.errors[:fetched_at]).to be_present
    end
  end

  describe "dependent destroy" do
    it "destroys associated top_track_results when the batch is destroyed" do
      batch = TopTrackBatch.create!(
        spotify_user_id: "user123",
        time_range:      "medium_term",
        limit:           5,
        fetched_at:      Time.current
      )

      result1 = TopTrackResult.create!(
        top_track_batch: batch,
        spotify_id:      "track1",
        name:            "Track 1",
        position:        1
      )

      result2 = TopTrackResult.create!(
        top_track_batch: batch,
        spotify_id:      "track2",
        name:            "Track 2",
        position:        2
      )

      expect { batch.destroy }.to change(TopTrackResult, :count).by(-2)
      expect(TopTrackResult.where(id: [ result1.id, result2.id ])).to be_empty
    end
  end
end
