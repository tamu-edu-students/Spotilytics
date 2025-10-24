class TopTracksController < ApplicationController
  def index
    # basic auth guard: if there's no user info in session, bounce
    if session[:spotify_user].nil?
      redirect_to root_path, alert: "Please sign in with Spotify first."
      return
    end

    client = SpotifyClient.new(session: session)

    # For sprint-1, we want the data for the last 1 year
    # For next sprint, we can add more data and different ranges.
    @tracks = client.top_tracks(limit: 10, time_range: "short_term")

  rescue SpotifyClient::UnauthorizedError => e
    Rails.logger.error "Spotify unauthorized: #{e.message}"
    redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
  rescue SpotifyClient::Error => e
    Rails.logger.error "Spotify API error: #{e.message}"
    @error = "Couldn't load your top tracks from Spotify."
    @tracks = []
  rescue => e
    Rails.logger.error "Unexpected error in TopTracksController#index: #{e.message}"
    @error = "Something went wrong."
    @tracks = []
  end
end
