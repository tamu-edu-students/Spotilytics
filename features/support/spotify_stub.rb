require 'ostruct'
require Rails.root.join('app/services/spotify_client')

module SpotifyStub
  LONG_TERM_RANGE = 'long_term'.freeze

  def stub_spotify_top_artists(n = 10)
    artists = build_stubbed_artists(n)

    allow_any_instance_of(SpotifyClient).to receive(:top_artists) do |_, *args, **kwargs|
      options = extract_options(args, kwargs)

      limit = options[:limit] || n
      time_range = options[:time_range]

      @stubbed_top_artists_call = { limit: limit, time_range: time_range }

      unless time_range == LONG_TERM_RANGE
        raise ArgumentError, "Expected time_range '#{LONG_TERM_RANGE}' but received #{time_range.inspect}"
      end

      artists
    end

    @stubbed_top_artists = artists
  end

  def stubbed_top_artists_call
    @stubbed_top_artists_call
  end

  private

  def build_stubbed_artists(n)
    (1..n).map do |i|
      OpenStruct.new(
        name: "Artist #{i}",
        id: "artist_#{i}",
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
