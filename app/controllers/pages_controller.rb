class PagesController < ApplicationController
  before_action :require_spotify_auth!, only: %i[dashboard top_artists top_tracks]

  def home
  end

  def dashboard
    # Top Artists
    @top_artists = fetch_top_artists(limit: 10)
    @primary_artist = @top_artists.first

    # Top Tracks
    @top_tracks = fetch_top_tracks(limit: 10)
    @primary_track = @top_tracks.first

  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: 'You must log in with spotify to access the dashboard.' and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top artists for dashboard: #{e.message}"
    flash.now[:alert] = 'We were unable to load your Spotify data right now. Please try again later.'
    @top_artists = []
    @primary_artist = nil
    @top_tracks = []
    @primary_track = nil
  end

  def top_artists
    @top_artists = fetch_top_artists(limit: 10)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: 'You must log in with spotify to view your top artists.' and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top artists: #{e.message}"
    flash.now[:alert] = 'We were unable to load your top artists from Spotify. Please try again later.'
    @top_artists = []
  end

  def top_tracks
    @top_tracks = fetch_top_tracks(limit: 10)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: 'You must log in with spotify to view your top tracks.' and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top tracks: #{e.message}"
    flash.now[:alert] = 'We were unable to load your top tracks from Spotify. Please try again later.'
    @top_tracks = []
  end
  
  private

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end

  def fetch_top_artists(limit:)
    spotify_client.top_artists(limit: limit, time_range: 'long_term')
  end

  def fetch_top_tracks(limit:)
    spotify_client.top_tracks(limit: limit, time_range: 'long_term')
  end
end
