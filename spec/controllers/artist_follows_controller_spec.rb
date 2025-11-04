require 'rails_helper'
require 'set'

RSpec.describe ArtistFollowsController, type: :controller do
  let(:spotify_client) { instance_double(SpotifyClient) }
  let(:spotify_id) { 'artist_123' }

  before do
    session[:spotify_user] = { 'email' => 'listener@example.com' }
    allow(SpotifyClient).to receive(:new).with(session: anything).and_return(spotify_client)
    request.env['HTTP_REFERER'] = top_artists_path
  end

  describe '#create' do
    it 'follows an artist and redirects back with notice' do
      allow(spotify_client).to receive(:follow_artists).with([spotify_id]).and_return(true)

      post :create, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(top_artists_path)
      expect(flash[:notice]).to eq('Artist followed.')
      expect(spotify_client).to have_received(:follow_artists).with([spotify_id])
    end

    it 'redirects to login and clears tokens when scope is missing' do
      session[:spotify_token] = 'token'
      session[:spotify_refresh_token] = 'refresh'
      session[:spotify_expires_at] = 123

      allow(spotify_client).to receive(:follow_artists)
        .and_raise(SpotifyClient::Error.new('Insufficient client scope'))

      post :create, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq('Spotify now needs permission to manage your follows. Please sign in again.')
      expect(session[:spotify_token]).to be_nil
      expect(session[:spotify_refresh_token]).to be_nil
      expect(session[:spotify_expires_at]).to be_nil
    end

    it 'redirects back with the original error message for other errors' do
      allow(spotify_client).to receive(:follow_artists)
        .and_raise(SpotifyClient::Error.new('rate limited'))

      post :create, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(top_artists_path)
      expect(flash[:alert]).to eq('Unable to follow artist: rate limited')
    end
  end

  describe '#destroy' do
    before do
      allow(spotify_client).to receive(:unfollow_artists).and_return(true)
    end

    it 'unfollows an artist and redirects back with notice' do
      delete :destroy, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(top_artists_path)
      expect(flash[:notice]).to eq('Artist unfollowed.')
      expect(spotify_client).to have_received(:unfollow_artists).with([spotify_id])
    end

    it 'redirects to login and clears tokens when scope is missing' do
      session[:spotify_token] = 'token'
      session[:spotify_refresh_token] = 'refresh'
      session[:spotify_expires_at] = 123

      allow(spotify_client).to receive(:unfollow_artists)
        .and_raise(SpotifyClient::Error.new('Insufficient client scope'))

      delete :destroy, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq('Spotify now needs permission to manage your follows. Please sign in again.')
      expect(session[:spotify_token]).to be_nil
      expect(session[:spotify_refresh_token]).to be_nil
      expect(session[:spotify_expires_at]).to be_nil
    end

    it 'redirects back with message when unfollow fails for other reasons' do
      allow(spotify_client).to receive(:unfollow_artists)
        .and_raise(SpotifyClient::Error.new('service unavailable'))

      delete :destroy, params: { spotify_id: spotify_id }

      expect(response).to redirect_to(top_artists_path)
      expect(flash[:alert]).to eq('Unable to unfollow artist: service unavailable')
    end
  end
end
