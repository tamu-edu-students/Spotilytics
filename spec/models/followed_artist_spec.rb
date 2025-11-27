require "rails_helper"

RSpec.describe FollowedArtist, type: :model do
  describe "associations" do
    it "belongs to a followed_artist_batch" do
      assoc = described_class.reflect_on_association(:followed_artist_batch)
      expect(assoc).not_to be_nil
      expect(assoc.macro).to eq(:belongs_to)
    end
  end

  describe "basic persistence" do
    it "persists its attributes (including genres) correctly" do
      batch = FollowedArtistBatch.create!(
        spotify_user_id: "user123",
        limit: 20,
        fetched_at: Time.current
      )

      artist = described_class.create!(
        followed_artist_batch: batch,
        spotify_id: "artist_123",
        name: "Test Artist",
        image_url: "http://example.com/a.jpg",
        popularity: 50,
        spotify_url: "http://spotify.com/a",
        genres: [ "rock", "pop" ],
        position: 1
      )

      artist.reload
      expect(artist.spotify_id).to eq("artist_123")
      expect(artist.name).to eq("Test Artist")
      expect(artist.genres.to_s).to include("rock")
    end
  end
end
