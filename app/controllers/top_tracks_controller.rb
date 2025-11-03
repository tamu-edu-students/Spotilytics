class TopTracksController < ApplicationController
  before_action :require_spotify_auth!

  TIME_RANGES = [
    { key: 'short_term',  label: 'Last 4 Weeks' },
    { key: 'medium_term', label: 'Last 6 Months' },
    { key: 'long_term',   label: 'Last 1 Year' }
  ].freeze

  def index
    client = SpotifyClient.new(session: session)

    @limits = {
      'short_term'  => normalize_limit(params[:limit_short_term]),
      'medium_term' => normalize_limit(params[:limit_medium_term]),
      'long_term'   => normalize_limit(params[:limit_long_term])
    }

    @time_ranges = TIME_RANGES

    begin
      @tracks_short  = client.top_tracks(limit: @limits['short_term'],  time_range: 'short_term')
      @tracks_medium = client.top_tracks(limit: @limits['medium_term'], time_range: 'medium_term')
      @tracks_long   = client.top_tracks(limit: @limits['long_term'],   time_range: 'long_term')
      @error = nil
    rescue SpotifyClient::UnauthorizedError => e
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
      return
    rescue SpotifyClient::Error => e
      @tracks_short  = []
      @tracks_medium = []
      @tracks_long   = []
      @error = "Couldn't load your top tracks from Spotify."
    end
  end

  private

  def normalize_limit(v)
    n = v.to_i
    [10, 25, 50].include?(n) ? n : 10
  end

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end
end
