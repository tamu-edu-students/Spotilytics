require 'rails_helper'
require 'ostruct'
require 'set'

RSpec.describe "ArtistFollows", type: :request do
  include SpotifyStub

  let(:artist_id) { 'long_term_artist_1' }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(OpenStruct.new(email: 'test@example.com'))
    stub_spotify_top_artists(10)
  end

  describe "POST /artist_follows" do
    it "follows the artist and redirects back to top artists" do
      post artist_follows_path, params: { spotify_id: artist_id }

      expect(response).to redirect_to(top_artists_path)
      expect(follow_calls.last).to include(artist_id)
      expect(stubbed_followed_artist_ids).to include(artist_id)
    end
  end

  describe "DELETE /artist_follows/:spotify_id" do
    it "unfollows the artist and redirects back to top artists" do
      set_stub_followed_artists([artist_id])

      delete artist_follow_path(artist_id)

      expect(response).to redirect_to(top_artists_path)
      expect(unfollow_calls.last).to include(artist_id)
      expect(stubbed_followed_artist_ids).not_to include(artist_id)
    end
  end
end
