class MonthlyListeningStats
  MILLIS_IN_HOUR = 3_600_000.0

  def initialize(client:, time_zone: Time.zone)
    @client = client
    @time_zone = time_zone
  end

  def summary(limit: 500)
    plays = Array(client.recently_played(limit: limit))
    return empty_summary if plays.empty?

    buckets = Hash.new { |h, k| h[k] = { duration_ms: 0, play_count: 0 } }
    timestamps = []

    plays.each do |play|
      time = normalize_time(play&.played_at)
      next unless time

      timestamps << time
      bucket_key = time.beginning_of_month
      bucket = buckets[bucket_key]
      bucket[:duration_ms] += extract_duration(play)
      bucket[:play_count] += 1
    end

    ordered_months = buckets.keys.sort
    monthly_rows = ordered_months.map do |month|
      data = buckets[month]
      {
        month: month,
        label: month.strftime("%b %Y"),
        duration_ms: data[:duration_ms],
        hours: hours_from_ms(data[:duration_ms]),
        play_count: data[:play_count]
      }
    end

    {
      buckets: monthly_rows,
      sample_size: buckets.values.sum { |v| v[:play_count] },
      total_duration_ms: buckets.values.sum { |v| v[:duration_ms] },
      history_window: build_history_window(timestamps)
    }
  end

  def chart_data(limit: 500)
    result = summary(limit: limit)
    buckets = result[:buckets]

    chart = if buckets.empty?
      { labels: [], datasets: [] }
    else
      {
        labels: buckets.map { |b| b[:label] },
        datasets: [
          {
            label: "Hours listened",
            data: buckets.map { |b| b[:hours].round(2) }
          }
        ]
      }
    end

    result.merge(chart: chart)
  end

  private

  attr_reader :client, :time_zone

  def normalize_time(value)
    return nil if value.blank?

    time = value.is_a?(Time) ? value : Time.parse(value.to_s)
    time_zone ? time.in_time_zone(time_zone) : time
  rescue ArgumentError
    nil
  end

  def extract_duration(play)
    duration = if play.respond_to?(:duration_ms)
      play.duration_ms
    else
      play[:duration_ms]
    end

    duration.to_i
  rescue NoMethodError
    0
  end

  def hours_from_ms(duration_ms)
    (duration_ms.to_f / MILLIS_IN_HOUR).round(2)
  end

  def build_history_window(times)
    return nil if times.blank?
    [ times.min, times.max ]
  end

  def empty_summary
    { buckets: [], sample_size: 0, total_duration_ms: 0, history_window: nil, chart: { labels: [], datasets: [] } }
  end
end
