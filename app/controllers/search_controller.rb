class SearchController < ApplicationController
  before_action :require_spotify_auth!, only: %i[index]

  def index
    query = params[:query].to_s.strip
    return unless query.present?

    # Prefer your SpotifyClient (returns OpenStruct objects like top_tracks)
    if defined?(SpotifyClient)
      begin
        results = spotify_client.search(query)
        @artists = results[:artists] || []
        @tracks  = results[:tracks]  || []
        @albums  = results[:albums]  || []
        return
      rescue => e
        Rails.logger.warn "SpotifyClient search failed, falling back to RSpotify: #{e.message}"
      end
    end

    # Fallback to RSpotify if no SpotifyClient or an error occurred
    begin
      @artists = RSpotify::Artist.search(query, limit: 10)
      @tracks  = RSpotify::Track.search(query, limit: 20)
      @albums  = RSpotify::Album.search(query, limit: 10)
    rescue => e
      Rails.logger.error("Spotify Search Error (RSpotify): #{e.message}")
      @artists = []
      @tracks  = []
      @albums  = []
    end
  end

  private

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end
end
