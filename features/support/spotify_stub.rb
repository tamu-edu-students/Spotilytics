require 'ostruct'
require 'set'
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
    @stubbed_followed_artist_ids = Set.new
    @stubbed_followed_artist_ids_requests = []

    allow_any_instance_of(SpotifyClient).to receive(:followed_artist_ids) do |_, ids|
      ids = Array(ids).map(&:to_s)
      @stubbed_followed_artist_ids_requests << ids
      ids.each_with_object(Set.new) do |id, acc|
        acc << id if @stubbed_followed_artist_ids.include?(id)
      end
    end

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

    allow_any_instance_of(SpotifyClient).to receive(:follow_artists) do |_, ids|
      ids = Array(ids).map(&:to_s)
      ids.each { |id| @stubbed_followed_artist_ids << id }
      true
    end

    allow_any_instance_of(SpotifyClient).to receive(:unfollow_artists) do |_, ids|
      ids = Array(ids).map(&:to_s)
      ids.each { |id| @stubbed_followed_artist_ids.delete(id) }
      true
    end
  end

  def stubbed_top_artists_calls
    @stubbed_top_artists_calls || []
  end

  def stubbed_top_artists_for(range)
    (@stubbed_top_artists || {})[range]
  end

  def stubbed_followed_artist_ids
    @stubbed_followed_artist_ids || Set.new
  end

  def mark_artist_followed!(ids)
    ids = Array(ids).map(&:to_s)
    @stubbed_followed_artist_ids ||= Set.new
    ids.each { |id| @stubbed_followed_artist_ids << id }
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
