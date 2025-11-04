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

    @_followed_artist_ids = Set.new
    @_follow_calls = []
    @_unfollow_calls = []
    @_followed_artist_ids_requests = []
    @_next_follow_error = nil
    @_next_unfollow_error = nil

    RSpec.current_example.metadata[:stubbed_spotify_top_artists] = artists_by_range if defined?(RSpec) && RSpec.respond_to?(:current_example)
    @_stubbed_spotify_top_artists = artists_by_range
    @_spotify_top_artist_calls = []

    allow_any_instance_of(SpotifyClient).to receive(:top_artists) do |_, *args, **kwargs|
      options = extract_options(args, kwargs)

      limit = options[:limit] || n
      time_range = options[:time_range] || DEFAULT_TIME_RANGE

      unless ALLOWED_TIME_RANGES.include?(time_range)
        raise ArgumentError, "Expected time_range in #{ALLOWED_TIME_RANGES.inspect} but received #{time_range.inspect}"
      end

      call = { limit: limit, time_range: time_range }
      @_spotify_top_artist_calls << call

      artists_by_range[time_range]
    end

    allow_any_instance_of(SpotifyClient).to receive(:followed_artist_ids) do |_, ids|
      ids = Array(ids).map(&:to_s)
      @_followed_artist_ids_requests << ids
      ids.each_with_object(Set.new) do |id, acc|
        acc << id if @_followed_artist_ids.include?(id)
      end
    end

    allow_any_instance_of(SpotifyClient).to receive(:follow_artists) do |_, ids|
      if @_next_follow_error
        error = @_next_follow_error
        @_next_follow_error = nil
        raise error
      end
      ids = Array(ids).map(&:to_s)
      @_follow_calls << ids
      ids.each { |id| @_followed_artist_ids << id }
      true
    end

    allow_any_instance_of(SpotifyClient).to receive(:unfollow_artists) do |_, ids|
      if @_next_unfollow_error
        error = @_next_unfollow_error
        @_next_unfollow_error = nil
        raise error
      end
      ids = Array(ids).map(&:to_s)
      @_unfollow_calls << ids
      ids.each { |id| @_followed_artist_ids.delete(id) }
      true
    end

    artists_by_range[DEFAULT_TIME_RANGE]
  end

  def last_spotify_top_artists_call
    (@_spotify_top_artist_calls || []).last
  end

  def all_spotify_top_artists_calls
    @_spotify_top_artist_calls || []
  end

  def stubbed_followed_artist_ids
    @_followed_artist_ids || Set.new
  end

  def follow_calls
    @_follow_calls || []
  end

  def unfollow_calls
    @_unfollow_calls || []
  end

  def set_stub_followed_artists(ids)
    @_followed_artist_ids = Set.new(Array(ids).map(&:to_s))
  end

  def followed_artist_ids_requests
    @_followed_artist_ids_requests || []
  end

  def simulate_follow_error!(message = 'Insufficient client scope')
    @_next_follow_error = SpotifyClient::Error.new(message)
  end

  def simulate_unfollow_error!(message = 'Insufficient client scope')
    @_next_unfollow_error = SpotifyClient::Error.new(message)
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

RSpec.configure do |config|
  config.include SpotifyStub
end
