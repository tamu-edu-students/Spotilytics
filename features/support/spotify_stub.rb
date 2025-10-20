module SpotifyStub
  def stub_spotify_top_artists(n = 10)
    # Use a very small HTML stub via the app's view helpers if needed, but
    # typically the app will call a client class; stub that here.
    artists = (1..n).map do |i|
      OpenStruct.new(name: "Artist #{i}", id: "artist_#{i}", playcount: (n - i + 1) * 100)
    end

    if defined?(SpotifyClient)
      allow_any_instance_of(SpotifyClient).to receive(:top_artists).and_return(artists)
    else
      # store in world for steps to read if the app reads from session or similar
      @stubbed_top_artists = artists
    end
  end
end

World(SpotifyStub)
