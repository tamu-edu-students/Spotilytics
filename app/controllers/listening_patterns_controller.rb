class ListeningPatternsController < ApplicationController
  before_action :require_spotify_auth!

  VALID_LIMITS = [ 50, 100, 250, 500, 1000 ].freeze

  def hourly
    @limit = normalize_limit(params[:limit])
    client = SpotifyClient.new(session: session)
    history = ListeningHistory.new(spotify_user_id: spotify_user_id)

    # Fetch new data from Spotify (~50), persist to DB, then read as many as requested
    ingest_recent_plays!(client: client, history: history, fetch_limit: 200)

    plays = history.recent_entries(limit: @limit)
    @sample_size = plays.size
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

  def calendar
    client = SpotifyClient.new(session: session)
    history = ListeningHistory.new(spotify_user_id: spotify_user_id)

    ingest_recent_plays!(client: client, history: history, fetch_limit: 200)
    plays = history.recent_entries(limit: 500) # use larger window for calendar if available
    @sample_size = plays.size

    date_counts = Hash.new(0)
    timestamps  = []

    Array(plays).each do |play|
      time = normalize_time(play.played_at)
      next unless time
      timestamps << time
      date_counts[time.to_date] += 1
    end

    today      = Time.zone ? Time.zone.today : Date.today
    start_date = align_to_week_start(today - 55) # ~8 weeks, GitHub-style grid
    end_date   = today
    max_count  = date_counts.values.max.to_i

    @weeks = build_weeks(start_date, end_date, date_counts, max_count)
    @history_window = build_history_window(timestamps)
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your listening patterns." and return
  rescue SpotifyClient::Error => e
    if insufficient_scope?(e)
      reset_spotify_session!
      redirect_to login_path, alert: "Spotify now needs permission to read your Recently Played history. Please sign in again." and return
    else
      Rails.logger.warn "Failed to fetch listening calendar data: #{e.message}"
      flash.now[:alert] = "We weren't able to load your listening history from Spotify right now."
      @weeks = []
      @history_window = nil
      @sample_size = 0
    end
  end

  def monthly
    @limit = params[:limit].present? ? normalize_limit(params[:limit]) : 500
    client = SpotifyClient.new(session: session)
    stats_service = MonthlyListeningStats.new(client: client, time_zone: Time.zone)

    summary = stats_service.chart_data(limit: @limit)

    @chart_data = summary[:chart]
    @buckets = summary[:buckets]
    @sample_size = summary[:sample_size]
    @history_window = summary[:history_window]
    @total_hours = hours_from_ms(summary[:total_duration_ms])
  rescue SpotifyClient::UnauthorizedError
    redirect_to home_path, alert: "You must log in with spotify to view your listening patterns." and return
  rescue SpotifyClient::Error => e
    if insufficient_scope?(e)
      reset_spotify_session!
      redirect_to login_path, alert: "Spotify now needs permission to read your Recently Played history. Please sign in again." and return
    else
      Rails.logger.warn "Failed to fetch monthly listening data: #{e.message}"
      flash.now[:alert] = "We weren't able to load your listening history from Spotify right now."
      @chart_data = nil
      @buckets = []
      @sample_size = 0
      @history_window = nil
      @total_hours = 0
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

  def align_to_week_start(date)
    date - date.wday
  end

  def ingest_recent_plays!(client:, history:, fetch_limit:)
    recent = client.recently_played(limit: fetch_limit)
    history.ingest!(recent)
  end

  def spotify_user_id
    session.dig(:spotify_user, "id")
  end

  def build_weeks(start_date, end_date, counts, max_count)
    cells = []
    date = start_date

    while date <= end_date
      count = counts[date]
      cells << {
        date: date,
        count: count,
        level: intensity_level(count, max_count)
      }
      date += 1
    end

    cells.each_slice(7).to_a
  end

  def intensity_level(count, max)
    return 0 if count.to_i <= 0 || max <= 0
    ratio = count.to_f / max.to_f

    case ratio
    when 0...0.25 then 1
    when 0.25...0.5 then 2
    when 0.5...0.75 then 3
    else 4
    end
  end

  def insufficient_scope?(error)
    error.message.to_s.downcase.include?("insufficient client scope")
  end

  def hours_from_ms(ms)
    (ms.to_f / 3_600_000.0).round(1)
  end

  def reset_spotify_session!
    session.delete(:spotify_token)
    session.delete(:spotify_refresh_token)
    session.delete(:spotify_expires_at)
  end
end
