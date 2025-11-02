class PagesController < ApplicationController
  before_action :require_spotify_auth!, only: %i[dashboard top_artists top_tracks]

  TOP_ARTIST_TIME_RANGES = [
    { key: 'long_term', label: 'Past Year' },
    { key: 'medium_term', label: 'Past 6 Months' },
    { key: 'short_term', label: 'Past 4 Weeks' }
  ].freeze

  def home
  end

  def dashboard
    # Top Artists
    @top_artists = fetch_top_artists(limit: 10)
    @primary_artist = @top_artists.first

    # Top Tracks
    @top_tracks = fetch_top_tracks(limit: 10)
    @primary_track = @top_tracks.first

    build_genre_chart!(@top_artists)

  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: 'You must log in with spotify to access the dashboard.' and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top artists for dashboard: #{e.message}"
    flash.now[:alert] = 'We were unable to load your Spotify data right now. Please try again later.'
    @top_artists = []
    @primary_artist = nil
    @top_tracks = []
    @primary_track = nil
    @genre_chart = nil
  end

  def top_artists
    @time_ranges = TOP_ARTIST_TIME_RANGES
    @top_artists_by_range = {}
    @limits               = {}

    @time_ranges.each do |range|
      key        = range[:key]                              # "long_term" | "medium_term" | "short_term"
      param_name = "limit_#{key}"                           # "limit_long_term", etc.
      limit      = normalize_limit(params[param_name])      # default to 10 when blank/invalid

    @limits[key] = limit
    @top_artists_by_range[range[:key]] = fetch_top_artists(limit: limit, time_range: range[:key])
    end
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: 'You must log in with spotify to view your top artists.' and return
  rescue SpotifyClient::Error => e
    Rails.logger.warn "Failed to fetch Spotify top artists: #{e.message}"
    flash.now[:alert] = 'We were unable to load your top artists from Spotify. Please try again later.'
    @top_artists_by_range = TOP_ARTIST_TIME_RANGES.each_with_object({}) do |range, acc|
      acc[range[:key]] = []
    @limits = TOP_ARTIST_TIME_RANGES.map { |r| [r[:key], 10] }.to_h
    end
    @time_ranges = TOP_ARTIST_TIME_RANGES
  end

  def top_tracks
    limit = normalize_limit(params[:limit])
    @top_tracks = fetch_top_tracks(limit: limit)
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

  def fetch_top_artists(limit:, time_range: 'long_term')
    spotify_client.top_artists(limit: limit, time_range: time_range)
  end

  def fetch_top_tracks(limit:)
    spotify_client.top_tracks(limit: limit, time_range: 'long_term')
  end

  # Accept only 10, 25, 50; default to 10
  def normalize_limit(value)
    v = value.to_i
    [10, 25, 50].include?(v) ? v : 10
  end

  def build_genre_chart!(artists)
    counts = Hash.new(0)

    Array(artists).each do |a|
      genres = a.respond_to?(:genres) ? a.genres : Array(a['genres'])
      next if genres.blank?
      genres.each do |g|
        g = g.to_s.strip.downcase
        next if g.empty?
        counts[g] += 1         # count artists per genre
      end
    end

    if counts.empty?
      @genre_chart = nil
      return
    end

    sorted = counts.sort_by { |(_, c)| -c }
    top_n = 8
    top   = sorted.first(top_n)
    other = sorted.drop(top_n).sum { |(_, c)| c }

    labels = top.map { |(g, _)| g.split.map(&:capitalize).join(' ') }
    data   = top.map(&:last)
    if other > 0
      labels << "Other"
      data   << other
    end

    @genre_chart = {
      labels: labels,
      datasets: [
        {
          label: "Top Artist Genres",
          data: data
        }
      ]
    }
  end
end
