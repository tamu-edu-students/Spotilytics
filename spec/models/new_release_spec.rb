require "rails_helper"

RSpec.describe NewRelease, type: :model do
  describe "associations" do
    it "belongs to a new_release_batch" do
      assoc = described_class.reflect_on_association(:new_release_batch)
      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "basic persistence" do
    it "persists its attributes properly" do
      batch = NewReleaseBatch.create!(
        limit: 20,
        fetched_at: Time.current
      )

      release = described_class.create!(
        new_release_batch: batch,
        spotify_id: "alb1",
        name: "Album One",
        image_url: "http://img/a1.jpg",
        total_tracks: 10,
        release_date: "2024-01-01",
        spotify_url: "http://spotify.com/a1",
        position: 1
      )

      release.reload
      expect(release.spotify_id).to eq("alb1")
      expect(release.name).to eq("Album One")
      expect(release.total_tracks).to eq(10)
      expect(release.image_url).to eq("http://img/a1.jpg")
    end
  end
end