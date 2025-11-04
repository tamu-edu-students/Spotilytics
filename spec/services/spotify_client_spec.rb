require 'rails_helper'

def build_client(session_overrides = {})
  default_session = {
    spotify_token: 'token',
    spotify_refresh_token: 'refresh',
    spotify_expires_at: 1.hour.from_now.to_i
  }
  SpotifyClient.new(session: default_session.merge(session_overrides))
end

RSpec.describe SpotifyClient, type: :service do
  before do
    allow(ENV).to receive(:[]) { |key| { 'SPOTIFY_CLIENT_ID' => 'id', 'SPOTIFY_CLIENT_SECRET' => 'secret' }[key] }
  end

  describe '#follow_artists' do
    it 'deduplicates ids and sends a PUT request' do
      client = build_client
      expect(client).to receive(:request_with_json)
        .with(Net::HTTP::Put, '/me/following', 'token', params: { type: 'artist' }, body: { ids: %w[a1 a2] })
      allow(client).to receive(:ensure_access_token!).and_return('token')

      client.follow_artists(['a1', 'a2', 'a1'])
    end
  end

  describe '#unfollow_artists' do
    it 'deduplicates ids before issuing delete request' do
      client = build_client
      allow(client).to receive(:ensure_access_token!).and_return('abc')
      expect(client).to receive(:request_with_json)
        .with(Net::HTTP::Delete, '/me/following', 'abc', params: { type: 'artist' }, body: { ids: %w[x1 x2] })

      client.unfollow_artists(['x1', 'x1', 'x2'])
    end
  end

  describe '#followed_artist_ids' do
    it 'chunks requests to 50 IDs' do
      client = build_client
      allow(client).to receive(:ensure_access_token!).and_return('access')

      ids = (1..120).map { |i| "artist_#{i}" }
      first_chunk = Array.new(50, true)
      second_chunk = Array.new(50, false)
      third_chunk = [true] + Array.new(19, false)

      expect(client).to receive(:get)
        .with('/me/following/contains', 'access', type: 'artist', ids: ids.first(50).join(','))
        .and_return(first_chunk)
      expect(client).to receive(:get)
        .with('/me/following/contains', 'access', type: 'artist', ids: ids[50, 50].join(','))
        .and_return(second_chunk)
      expect(client).to receive(:get)
        .with('/me/following/contains', 'access', type: 'artist', ids: ids.last(20).join(','))
        .and_return(third_chunk)

      result = client.followed_artist_ids(ids)
      expect(result.size).to eq(51) # 50 from first chunk + 1 from third chunk
      expect(result).to include('artist_1', 'artist_50', 'artist_101')
      expect(result).not_to include('artist_51', 'artist_120')
    end
  end
end
