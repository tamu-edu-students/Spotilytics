require "rails_helper"

RSpec.describe FollowedArtistBatch, type: :model do
  describe "associations" do
    it "has many followed_artists" do
      assoc = described_class.reflect_on_association(:followed_artists)
      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:has_many)
    end
  end

  describe "basic persistence" do
    it "can create a batch and associated followed_artists" do
      batch = described_class.create!(
        spotify_user_id: "user123",
        limit: 20,
        fetched_at: Time.current
      )

      a1 = FollowedArtist.create!(
        followed_artist_batch: batch,
        spotify_id: "a1",
        name: "Artist 1",
        position: 1
      )

      a2 = FollowedArtist.create!(
        followed_artist_batch: batch,
        spotify_id: "a2",
        name: "Artist 2",
        position: 2
      )

      expect(batch.followed_artists).to match_array([a1, a2])
    end
  end
end