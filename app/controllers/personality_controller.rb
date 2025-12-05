class PersonalityController < ApplicationController
  before_action :require_spotify_auth!

  def show
    client = SpotifyClient.new(session: session)
    history = ListeningHistory.new(spotify_user_id: spotify_user_id)

    ingest_recent_plays!(client: client, history: history, fetch_limit: 200)

    top_tracks = client.top_tracks(limit: 25, time_range: "long_term")
    track_ids = top_tracks.map(&:id).compact.uniq.first(50)
    audio_features = track_ids.any? ? client.track_audio_features(track_ids).values.compact : []

    recent_plays = history.recent_entries(limit: 300)
    hour_counts = hour_buckets(recent_plays)

    personality = MusicPersonality.new(features: audio_features, hour_counts: hour_counts)
    @summary = personality.summary
    @stats = personality.stats
    @examples = top_tracks.first(3)
    @sample_size = audio_features.size
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your music personality." and return
  rescue SpotifyClient::Error => e
    handle_spotify_error(e)
  end

  private

  def ingest_recent_plays!(client:, history:, fetch_limit:)
    recent = client.recently_played(limit: fetch_limit)
    history.ingest!(recent)
  end

  def hour_buckets(plays)
    counts = Hash.new(0)
    Array(plays).each do |play|
      time = play.played_at
      next unless time
      hour = normalize_time(time).hour
      counts[hour] += 1
    end
    counts
  end

  def normalize_time(value)
    return value if value.is_a?(ActiveSupport::TimeWithZone)
    t = value.is_a?(Time) ? value : Time.parse(value.to_s)
    Time.zone ? t.in_time_zone(Time.zone) : t
  rescue ArgumentError
    Time.current
  end

  def spotify_user_id
    session.dig(:spotify_user, "id")
  end

  def handle_spotify_error(error)
    if error.message.to_s.downcase.include?("insufficient client scope")
      reset_spotify_session!
      redirect_to login_path, alert: "Spotify now needs permission to read your Recently Played history. Please sign in again." and return
    else
      Rails.logger.warn "Failed to fetch personality data: #{error.message}"
      flash.now[:alert] = "We weren't able to load your Spotify data right now."
      @summary = nil
      @stats = {}
      @examples = []
      @sample_size = 0
    end
  end

  def reset_spotify_session!
    session.delete(:spotify_token)
    session.delete(:spotify_refresh_token)
    session.delete(:spotify_expires_at)
  end
end
