class PlaylistsController < ApplicationController
  before_action :require_spotify_auth!

  VALID_RANGES = {
    "short_term"  => { label: "Last 4 Weeks" },
    "medium_term" => { label: "Last 6 Months" },
    "long_term"   => { label: "Last 1 Year" }
  }.freeze

  def create
    time_range = params[:time_range].to_s

    unless VALID_RANGES.key?(time_range)
      redirect_to top_tracks_path, alert: "Invalid time range."
      return
    end

    client = SpotifyClient.new(session: session)

    begin
      # ---- Resolve user_id safely (handles old sessions) ----
      user_info   = (session[:spotify_user] || {}).dup
      indifferent = user_info.respond_to?(:with_indifferent_access) ? user_info.with_indifferent_access : user_info
      user_id     = indifferent[:id].presence || indifferent['id'].presence

      # Fallback: ask Spotify /me if not present in session (works for old logins)
      unless user_id.present?
        user_id = client.current_user_id
        # cache it back into the session for next time
        session[:spotify_user] ||= {}
        if session[:spotify_user].respond_to?(:merge!)
          session[:spotify_user].merge!({ "id" => user_id })
        else
          session[:spotify_user]["id"] = user_id
        end
      end

      # ---- Fetch tracks for the requested time range ----
      tracks = client.top_tracks(limit: 10, time_range: time_range)
      if tracks.empty?
        redirect_to top_tracks_path, alert: "No tracks available for #{VALID_RANGES[time_range][:label]}."
        return
      end

      # ---- Create playlist + add tracks ----
      playlist_name = "Your Top Tracks - #{VALID_RANGES[time_range][:label]}"
      playlist_desc = "Auto-created from Spotilytics • #{VALID_RANGES[time_range][:label]}"

      playlist_id = client.create_playlist_for(
        user_id:     user_id,
        name:        playlist_name,
        description: playlist_desc,
        public:      false
      )

      uris = tracks.map { |t| "spotify:track:#{t.id}" }
      client.add_tracks_to_playlist(playlist_id: playlist_id, uris: uris)

      redirect_to top_tracks_path, notice: "Playlist created on Spotify: #{playlist_name}"
    rescue SpotifyClient::UnauthorizedError => e
      Rails.logger.error "Spotify unauthorized in playlist create: #{e.message}"
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Spotify error creating playlist: #{e.message}"
      redirect_to top_tracks_path, alert: "Couldn't create playlist on Spotify."
    end
  end

  private

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end
end
