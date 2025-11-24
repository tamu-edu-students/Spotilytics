class ListeningPatternsController < ApplicationController
  before_action :require_spotify_auth!

  VALID_LIMITS = [ 25, 50 ].freeze

  def hourly
    @limit = normalize_limit(params[:limit])
    client = SpotifyClient.new(session: session)

    plays = client.recently_played(limit: @limit)
    @sample_size = Array(plays).size
    zoned_times = []
    hourly_counts = Array.new(24, 0)

    Array(plays).each do |play|
      time = normalize_time(play.played_at)
      next unless time

      zoned_times << time
      hourly_counts[time.hour] += 1
    end

    @total_plays = hourly_counts.sum
    @hourly_chart = build_chart(hourly_counts) if @total_plays.positive?
    @top_hours = pick_top_hours(hourly_counts)
    @history_window = build_history_window(zoned_times)
    @sample_tracks = Array(plays).first(6)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your listening patterns." and return
  rescue SpotifyClient::Error => e
    if insufficient_scope?(e)
      reset_spotify_session!
      redirect_to login_path, alert: "Spotify now needs permission to read your Recently Played history. Please sign in again." and return
    else
      Rails.logger.warn "Failed to fetch listening pattern data: #{e.message}"
      flash.now[:alert] = "We weren't able to load your listening history from Spotify right now."
      @sample_size = 0
      @total_plays = 0
      @hourly_chart = nil
      @top_hours = []
      @history_window = nil
      @sample_tracks = []
    end
  end

  private

  def normalize_limit(value)
    v = value.to_i
    VALID_LIMITS.include?(v) ? v : 100
  end

  def normalize_time(value)
    return nil if value.blank?

    time = value.is_a?(Time) ? value : Time.parse(value.to_s)
    Time.zone ? time.in_time_zone(Time.zone) : time
  rescue ArgumentError
    nil
  end

  def build_chart(counts)
    labels = (0..23).map { |h| format("%02d:00", h) }
    {
      labels: labels,
      datasets: [
        {
          label: "Listens",
          data: counts
        }
      ]
    }
  end

  def pick_top_hours(counts, top_n: 3)
    return [] if counts.all?(&:zero?)

    counts.each_with_index
          .sort_by { |(count, _hour)| -count }
          .first(top_n)
          .map { |count, hour| { label: hour_label(hour), count: count, hour: hour } }
  end

  def hour_label(hour)
    h = hour.to_i % 24
    meridian = h >= 12 ? "PM" : "AM"
    hour12 = h % 12
    hour12 = 12 if hour12.zero?
    "#{hour12} #{meridian}"
  end

  def build_history_window(times)
    return nil if times.blank?
    [ times.min, times.max ]
  end

  def insufficient_scope?(error)
    error.message.to_s.downcase.include?("insufficient client scope")
  end

  def reset_spotify_session!
    session.delete(:spotify_token)
    session.delete(:spotify_refresh_token)
    session.delete(:spotify_expires_at)
  end
end
