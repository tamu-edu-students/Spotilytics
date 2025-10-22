module SpotifyStub
  def stub_spotify_top_artists(n = 10)
    artists = (1..n).map do |i|
      {
        'name' => "Artist #{i}",
        'id' => "artist_#{i}",
        'playcount' => (n - i + 1) * 100
      }
    end
      if defined?(SpotifyClient)
        allow_any_instance_of(SpotifyClient).to receive(:top_artists).and_return(artists)
      else
        # expose for tests that may read a helper variable
        RSpec.current_example.metadata[:stubbed_spotify_top_artists] = artists if defined?(RSpec) && RSpec.respond_to?(:current_example)
        @_stubbed_spotify_top_artists = artists
      end
  end
end

RSpec.configure do |config|
  config.include SpotifyStub
end
