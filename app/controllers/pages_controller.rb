# app/controllers/pages_controller.rb
require "set"

class PagesController < ApplicationController
  before_action :require_spotify_auth!, only: %i[
    dashboard top_artists top_tracks view_profile clear
  ]

  TOP_ARTIST_TIME_RANGES = [
    { key: "long_term", label: "Past Year" },
    { key: "medium_term", label: "Past 6 Months" },
    { key: "short_term", label: "Past 4 Weeks" }
  ].freeze

  # -----------------------------------------------------
  # CLEAR CACHED DATA
  # -----------------------------------------------------
  def clear
    spotify_client.clear_user_cache
    redirect_to home_path, notice: "Data refreshed successfully"
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to refresh your data."
  end

  # -----------------------------------------------------
  # HOME + GLOBAL SEARCH
  # -----------------------------------------------------
  def home
    return unless params[:query].present?

    query = params[:query].strip

    begin
      results = spotify_client.search(query)

      @artists = results[:artists] || []
      @tracks  = results[:tracks]  || []
      @albums  = results[:albums]  || []
    rescue => e
      Rails.logger.error("Home Search Error: #{e.message}")
      @artists = []
      @tracks  = []
      @albums  = []
    end
  end

  # -----------------------------------------------------
  # DASHBOARD
  # -----------------------------------------------------
  def dashboard
    # fetch best-effort; let exceptions be handled by rescues below
    @top_artists = fetch_top_artists(limit: 10)
    @primary_artist = @top_artists.first

    @top_tracks = fetch_top_tracks(limit: 10)
    @primary_track = @top_tracks.first

    build_genre_chart!(@top_artists)

    @followed_artists = fetch_followed_artists(limit: 20)
    @new_releases = fetch_new_releases(limit: 2)
  rescue SpotifyClient::UnauthorizedError
    # user needs to re-auth — redirect them out to home to sign-in flow
    redirect_to home_path, alert: "You must log in with spotify to access the dashboard."
  rescue SpotifyClient::Error => e
    # Tests expect we render the page (not redirect) and show a flash.now alert
    Rails.logger.warn "Dashboard error: #{e.message}"
    flash.now[:alert] = "We were unable to load your Spotify data right now. Please try again later."
    # safe defaults so view doesn't blow up
    @top_artists = []
    @primary_artist = nil
    @top_tracks = []
    @primary_track = nil
    @genre_chart = nil
    @followed_artists = []
    @new_releases = []
  end

  # -----------------------------------------------------
  # PROFILE
  # -----------------------------------------------------
  def view_profile
    @profile = fetch_profile
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your profile."
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Profile fetch error: #{e.message}"
    flash.now[:alert] = "We were unable to load your Spotify data right now. Please try again later."
    @profile = nil
  end

  # -----------------------------------------------------
  # TOP ARTISTS
  # -----------------------------------------------------
  def top_artists
    @time_ranges = TOP_ARTIST_TIME_RANGES
    @top_artists_by_range = {}
    @limits = {}

    collected_ids = []

    @time_ranges.each do |range|
      key = range[:key]
      limit = normalize_limit(params["limit_#{key}"])
      @limits[key] = limit

      artists = fetch_top_artists(limit: limit, time_range: key)
      @top_artists_by_range[key] = artists
      collected_ids.concat(extract_artist_ids(artists))
    end

    unique_ids = collected_ids.uniq
    @followed_artist_ids = unique_ids.any? ? spotify_client.followed_artist_ids(unique_ids) : Set.new
  rescue SpotifyClient::UnauthorizedError
    # spec expects this exact string
    redirect_to home_path, alert: "You must log in with spotify to view your top artists."
  rescue SpotifyClient::Error => e
    # Special case: insufficient scope
    if insufficient_scope?(e)
      session[:spotify_user] = nil
      session[:spotify_token] = nil
      session[:spotify_refresh_token] = nil
      redirect_to login_path, alert: "Spotify now needs permission to access your top artists. Please log in again." and return
    end

    # Generic error fallback
    Rails.logger.warn "Top artists error: #{e.message}"
    flash.now[:alert] = "We were unable to load your Spotify data right now. Please try again later."

    @top_artists_by_range = TOP_ARTIST_TIME_RANGES.map { |r| [ r[:key], [] ] }.to_h
    @limits = TOP_ARTIST_TIME_RANGES.map { |r| [ r[:key], 10 ] }.to_h
    @followed_artist_ids = Set.new
  end


  # -----------------------------------------------------
  # TOP TRACKS
  # -----------------------------------------------------
  def top_tracks
    limit = normalize_limit(params[:limit])
    @top_tracks = fetch_top_tracks(limit: limit)
  rescue SpotifyClient::UnauthorizedError
    # spec expects this exact string
    redirect_to home_path, alert: "You must log in with spotify to view your top tracks."
  rescue SpotifyClient::Error => e
    # spec expects this exact logger message pattern:
    Rails.logger.warn "Failed to fetch Spotify top tracks: #{e.message}"
    flash.now[:alert] = "We were unable to load your top tracks from Spotify. Please try again later."
    @top_tracks = []
  end


  # -----------------------------------------------------
  # WRAPPED (added feature)
  # -----------------------------------------------------
  def wrapped
    # require spotify login
    begin
      require_spotify_auth!
    rescue
      redirect_to home_path, alert: "Please sign in with Spotify to view your wrapped." and return
    end

    # fetch data (safe: methods already exist in this controller)
    begin
      @top_artists = fetch_top_artists(limit: 5)
      @top_tracks  = fetch_top_tracks(limit: 8)
      build_genre_chart!(@top_artists) if @top_artists.present?
    rescue SpotifyClient::UnauthorizedError
      redirect_to home_path, alert: "Spotify session expired. Please sign in again." and return
    rescue SpotifyClient::Error => e
      Rails.logger.warn "Wrapped fetch error: #{e.message}"
      @top_artists = []
      @top_tracks  = []
      @genre_chart = nil
    end

    # Build slides: normalized hashes that the view expects
    @slides = []

    # Slide 0: main highlight (top artist)
    if @top_artists.present?
      primary = @top_artists.first
      name = primary.respond_to?(:name) ? primary.name : (primary["name"] rescue "Unknown Artist")
      image = primary.respond_to?(:image_url) ? primary.image_url : (primary.dig("images", 0, "url") rescue nil)
      genres = primary.respond_to?(:genres) ? (primary.genres || []).first : (primary["genres"]&.first)

      @slides << {
        type: :artist,
        title: name,
        subtitle: "Your top artist",
        image: image,
        body: genres
      }
    end

    # Next slides: top tracks
    @top_tracks.first(6).each do |t|
      title = t.respond_to?(:name) ? t.name : (t["name"] rescue "Unknown Track")
      artists = if t.respond_to?(:artists)
                  t.artists
      else
                  # t["artists"] may be array of hashes
                  arr = (t["artists"] || t[:artists] || [])
                  if arr.is_a?(Array) && arr.first
                    first = arr.first
                    first.is_a?(Hash) ? arr.map { |a| a["name"] }.join(", ") : arr.join(", ")
                  else
                    arr.to_s
                  end
      end
      image = t.respond_to?(:album_image_url) ? t.album_image_url : (t.dig("album", "images", 0, "url") rescue nil)
      preview = t.respond_to?(:preview_url) ? t.preview_url : (t["preview_url"] rescue nil)
      spotify_url = t.respond_to?(:spotify_url) ? t.spotify_url : (t.dig("external_urls", "spotify") rescue nil)
      popularity = t.respond_to?(:popularity) ? t.popularity : (t["popularity"] rescue nil)

      @slides << {
        type: :track,
        title: title,
        subtitle: artists,
        image: image,
        extras: {
          preview_url: preview,
          spotify_url: spotify_url,
          popularity: popularity
        }
      }
    end

    # Genre summary slide
    if @genre_chart.present? && @genre_chart[:labels].present?
      body = @genre_chart[:labels].zip(@genre_chart[:datasets].first[:data]).map { |label, count| "#{label} (#{count})" }.first(8).join(", ")
      @slides << {
        type: :genres,
        title: "Top genres",
        subtitle: nil,
        image: nil,
        body: body
      }
    end

    # fallback
    if @slides.empty?
      @slides << { type: :empty, title: "No Spotify data available", subtitle: nil, image: nil, body: nil }
    end
  end

  # -----------------------------------------------------
  # GENRE CHART BUILDER (used by dashboard + wrapped)
  # -----------------------------------------------------
  def build_genre_chart!(artists)
    counts = Hash.new(0)

    Array(artists).each do |a|
      genres =
        if a.respond_to?(:genres)
          a.genres
        else
          Array(a["genres"] || a[:genres])
        end

      next if genres.blank?

      genres.each do |g|
        g = g.to_s.strip.downcase
        next if g.empty?
        counts[g] += 1
      end
    end

    if counts.empty?
      @genre_chart = nil
      return
    end

    sorted = counts.sort_by { |_, c| -c }
    top_n = 8
    top   = sorted.first(top_n)
    other = sorted.drop(top_n).sum { |_, c| c }

    labels = top.map { |(g, _)| g.split.map(&:capitalize).join(" ") }
    data   = top.map(&:last)
    if other > 0
      labels << "Other"
      data   << other
    end

    @genre_chart = {
      labels: labels,
      datasets: [
        { label: "Top Artist Genres", data: data }
      ]
    }
  end

  # ====================================================
  # PRIVATE HELPERS
  # ====================================================
  private

  # If you keep the insufficient-scope behavior, keep these helpers:
  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end

  def fetch_profile
    spotify_client.profile
  end

  def fetch_new_releases(limit:)
    spotify_client.new_releases(limit: limit)
  end

  def fetch_top_artists(limit:, time_range: "long_term")
    spotify_client.top_artists(limit: limit, time_range: time_range)
  end

  def fetch_top_tracks(limit:)
    spotify_client.top_tracks(limit: limit, time_range: "long_term")
  end

  def fetch_followed_artists(limit:)
    spotify_client.followed_artists(limit: limit)
  end

  def normalize_limit(value)
    v = value.to_i
    [ 10, 25, 50 ].include?(v) ? v : 10
  end

  def extract_artist_ids(artists)
    Array(artists).map { |a| artist_identifier(a) }.compact
  end
  def insufficient_scope?(error)
    msg = error.message.to_s.downcase
    msg.include?("insufficient scope") || msg.include?("missing scope")
  end


  def artist_identifier(artist)
    artist.respond_to?(:id) ? artist.id : artist["id"]
  end
end
