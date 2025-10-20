module SpotifyStub
  def stub_spotify_top_artists(n = 10)
    artists = (1..n).map do |i|
      {
        'name' => "Artist #{i}",
        'id' => "artist_#{i}",
        'playcount' => (n - i + 1) * 100
      }
    end

    allow_any_instance_of(SpotifyClient).to receive(:top_artists).and_return(artists)
  end
end

RSpec.configure do |config|
  config.include SpotifyStub
end
