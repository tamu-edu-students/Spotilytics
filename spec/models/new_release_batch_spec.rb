require "rails_helper"

RSpec.describe NewReleaseBatch, type: :model do
  describe "associations" do
    it "has many new_releases" do
      assoc = described_class.reflect_on_association(:new_releases)
      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:has_many)
    end
  end

  describe "basic persistence" do
    it "creates a batch and associated new releases" do
      batch = described_class.create!(
        limit: 20,
        fetched_at: Time.current
      )

      r1 = NewRelease.create!(
        new_release_batch: batch,
        spotify_id: "alb1",
        name: "Album One",
        image_url: "http://img/a1.jpg",
        total_tracks: 10,
        release_date: "2024-01-01",
        spotify_url: "http://spotify.com/a1",
        position: 1
      )

      r2 = NewRelease.create!(
        new_release_batch: batch,
        spotify_id: "alb2",
        name: "Album Two",
        image_url: "http://img/a2.jpg",
        total_tracks: 12,
        release_date: "2024-02-01",
        spotify_url: "http://spotify.com/a2",
        position: 2
      )

      expect(batch.new_releases).to match_array([r1, r2])
    end
  end
end