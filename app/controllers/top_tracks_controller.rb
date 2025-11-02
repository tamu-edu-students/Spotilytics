class TopTracksController < ApplicationController
  before_action :require_spotify_auth!

  def index
    client = SpotifyClient.new(session: session)

    limit = params[:limit].to_i
    limit = 10 unless [10, 25, 50].include?(limit)

    begin
      @tracks_short  = client.top_tracks(limit: 10, time_range: "short_term")
      @tracks_medium = client.top_tracks(limit: 10, time_range: "medium_term")
      @tracks_long   = client.top_tracks(limit: 10, time_range: "long_term")
      @error = nil
    rescue SpotifyClient::UnauthorizedError => e
      Rails.logger.error "Spotify unauthorized: #{e.message}"
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
      return
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @tracks_short  = []
      @tracks_medium = []
      @tracks_long   = []
      @error = "Couldn't load your top tracks from Spotify."
    end
  end

  private

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end
end
