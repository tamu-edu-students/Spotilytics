# app/controllers/top_tracks_controller.rb
class TopTracksController < ApplicationController
  before_action :require_spotify_auth!

  def index
    client = SpotifyClient.new(session: session)

    limit = params[:limit].to_i
    limit = 10 unless [10, 25, 50].include?(limit)

    begin
      # For sprint-1, we want the data for the last 1 year
      # For next sprint, we can add more data and different ranges.
      # Fetch top 10 long-term tracks (~past 1 year per Spotify API docs)
      @tracks = client.top_tracks(limit: limit, time_range: "long_term")
      @error  = nil
    rescue SpotifyClient::UnauthorizedError => e
      Rails.logger.error "Spotify unauthorized: #{e.message}"
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
      return
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error: #{e.message}"
      @tracks = []
      @error  = "Couldn't load your top tracks from Spotify."
    end
  end

  private

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end
end
