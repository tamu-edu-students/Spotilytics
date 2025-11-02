require 'ostruct'
require Rails.root.join('app/services/spotify_client')

module SpotifyStub
  ALLOWED_TIME_RANGES = %w[long_term medium_term short_term].freeze
  DEFAULT_TIME_RANGE = 'long_term'.freeze

  def stub_spotify_top_artists(n = 10)
    artists_by_range = ALLOWED_TIME_RANGES.each_with_object({}) do |range, acc|
      acc[range] = build_stubbed_artists(n, prefix: range)
    end

    @stubbed_top_artists = artists_by_range
    @stubbed_top_artists_calls = []

    allow_any_instance_of(SpotifyClient).to receive(:top_artists) do |_, *args, **kwargs|
      options = extract_options(args, kwargs)

      limit = options[:limit] || n
      time_range = options[:time_range] || DEFAULT_TIME_RANGE

      unless ALLOWED_TIME_RANGES.include?(time_range)
        raise ArgumentError, "Expected time_range in #{ALLOWED_TIME_RANGES.inspect} but received #{time_range.inspect}"
      end

      call = { limit: limit, time_range: time_range }
      @stubbed_top_artists_calls << call

      artists_by_range[time_range]
    end
  end

  def stubbed_top_artists_calls
    @stubbed_top_artists_calls || []
  end

  def stubbed_top_artists_for(range)
    (@stubbed_top_artists || {})[range]
  end

  private

  def build_stubbed_artists(n, prefix:)
    label = prefix.split('_').map(&:capitalize).join(' ')

    (1..n).map do |i|
      OpenStruct.new(
        name: "#{label} Artist #{i}",
        id: "#{prefix}_artist_#{i}",
        playcount: (n - i + 1) * 100,
        popularity: (n - i + 1) * 10
      )
    end
  end

  def extract_options(args, kwargs)
    options = {}
    options.merge!(args.pop) if args.last.is_a?(Hash)
    options.merge!(kwargs) if kwargs.any?
    options
  end
end

World(SpotifyStub)
