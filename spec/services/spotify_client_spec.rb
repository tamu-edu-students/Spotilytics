require 'rails_helper'

RSpec.describe SpotifyClient do
  let(:session_store) do
    {
      spotify_token: 'token',
      spotify_refresh_token: 'refresh',
      spotify_expires_at: 1.hour.from_now.to_i
    }
  end

  subject(:client) { described_class.new(session: session_store) }

  before do
    allow(client).to receive(:ensure_access_token!).and_return('access')
  end

  describe '#follow_artists' do
    it 'deduplicates ids and sends a PUT request with JSON payload' do
      expect(client)
        .to receive(:request_with_json)
        .with(Net::HTTP::Put, '/me/following', 'access', params: { type: 'artist' }, body: { ids: %w[a1 a2] })

      client.follow_artists(['a1', 'a2', 'a1'])
    end
  end

  describe '#unfollow_artists' do
    it 'deduplicates ids and sends a DELETE request with JSON payload' do
      expect(client)
        .to receive(:request_with_json)
        .with(Net::HTTP::Delete, '/me/following', 'access', params: { type: 'artist' }, body: { ids: %w[a3 a4] })

      client.unfollow_artists(%w[a3 a4 a3])
    end
  end

  describe '#followed_artist_ids' do
    it 'chunks requests into groups of 50 and returns ids with true status' do
      ids = (1..55).map { |i| "artist_#{i}" }

      first_chunk = Array.new(50, true)
      second_chunk = [false, true, false, false, false]

      expect(client).to receive(:get)
        .with('/me/following/contains', 'access', type: 'artist', ids: ids.first(50).join(','))
        .and_return(first_chunk)

      expect(client).to receive(:get)
        .with('/me/following/contains', 'access', type: 'artist', ids: ids.drop(50).join(','))
        .and_return(second_chunk)

      result = client.followed_artist_ids(ids)

      expect(result.to_a).to match_array(ids.first(50) + [ids[51]])
    end
  end
end
