# app/controllers/playlists_controller.rb
class PlaylistsController < ApplicationController
  before_action :require_spotify_auth!

  VALID_RANGES = {
    "short_term"  => { label: "Last 4 Weeks" },
    "medium_term" => { label: "Last 6 Months" },
    "long_term"   => { label: "Last 1 Year" }
  }.freeze

  # -----------------------------------------------------
  # Create playlist from top tracks (existing feature)
  # -----------------------------------------------------
  def create
    time_range = params[:time_range].to_s

    unless VALID_RANGES.key?(time_range)
      redirect_to top_tracks_path, alert: "Invalid time range."
      return
    end

    client = spotify_client

    begin
      # ---- Resolve user_id safely (handles old sessions) ----
      user_info   = (session[:spotify_user] || {}).dup
      indifferent = user_info.respond_to?(:with_indifferent_access) ? user_info.with_indifferent_access : user_info
      user_id     = indifferent[:id].presence || indifferent["id"].presence

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
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify again."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Playlists#create error: #{e.message}"
      redirect_to top_tracks_path, alert: "Couldn't create playlist on Spotify."
    end
  end

  # -----------------------------------------------------
  # NEW: Index - list user's playlists
  # GET /playlists
  # -----------------------------------------------------
  def index
    client = spotify_client
    begin
      @playlists = client.user_playlists(limit: 50)
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Playlists#index error: #{e.message}"
      @playlists = []
      flash.now[:alert] = "Could not load playlists from Spotify."
      render :index
    end
  end

  # -----------------------------------------------------
  # NEW: Sort/Inspect - group playlist tracks by genre
  # GET /playlists/:id/sort
  # -----------------------------------------------------
  def sort
    playlist_id = params[:id].to_s
    client = spotify_client

    begin
      # find playlist metadata from user's playlists (safe quick check)
      @playlist = client.user_playlists(limit: 50).find { |p| p.id.to_s == playlist_id.to_s }
      unless @playlist
        redirect_to playlists_path, alert: "Playlist not found."
        return
      end

      # fetch tracks with genres
      tracks = client.playlist_tracks_with_genres(playlist_id)

      # keep valid entries and group by first genre (or 'Unknown')
      filtered = tracks.select { |t| t[:id].present? && t[:name].present? }
      @grouped = filtered.group_by do |t|
        (t[:genres].presence && t[:genres].first.presence) || "Unknown"
      end
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Playlists#sort error: #{e.message}"
      redirect_to playlists_path, alert: "Failed to fetch playlist tracks."
    end
  end

  # -----------------------------------------------------
  # NEW: Create per-genre playlists on the user's Spotify account
  # POST /playlists/:id/create_genre_playlists
  # -----------------------------------------------------
  def create_genre_playlists
    playlist_id = params[:id].to_s
    client = spotify_client

    begin
      tracks = client.playlist_tracks_with_genres(playlist_id)
      tracks = tracks.select { |t| t[:id].present? }

      grouped = tracks.group_by { |t| (t[:genres].presence && t[:genres].first.presence) || "Unknown" }
      user_id = client.current_user_id

      grouped.each do |genre, items|
        playlist_name = "#{genre} Mix - Spotilytics"
        playlist_desc = "Auto-generated from playlist #{playlist_id} • Genre: #{genre}"

        new_playlist_id = client.create_playlist_for(
          user_id:     user_id,
          name:        playlist_name,
          description: playlist_desc,
          public:      false
        )

        uris = items.map { |t| "spotify:track:#{t[:id]}" }.compact
        client.add_tracks_to_playlist(playlist_id: new_playlist_id, uris: uris) if uris.any?
      end

      redirect_to playlists_path, notice: "Genre playlists created successfully!"
    rescue SpotifyClient::UnauthorizedError
      redirect_to root_path, alert: "Session expired. Please sign in with Spotify."
    rescue SpotifyClient::Error => e
      Rails.logger.error "Playlists#create_genre_playlists error: #{e.message}"
      redirect_to playlists_path, alert: "Failed to create genre playlists."
    end
  end

  # -----------------------------------------------------
  # Helpers
  # -----------------------------------------------------
  private

  def require_spotify_auth!
    unless session[:spotify_user].present?
      redirect_to root_path, alert: "Please sign in with Spotify first."
    end
  end

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end
end
