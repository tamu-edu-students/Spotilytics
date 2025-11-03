class RecommendationsController < ApplicationController
    before_action :require_spotify_auth!

    def recommendations
        spotify_client = SpotifyClient.new(session: session)

        top_artists = spotify_client.top_artists(limit: 3, time_range: 'medium_term')
        top_tracks  = spotify_client.top_tracks(limit: 3, time_range: 'medium_term')

        # Combine artist names and track names into search queries
        search_queries = (top_artists.map(&:name) + top_tracks.map(&:name)).join(' OR ')

        @recommendations = spotify_client.search_tracks(search_queries, limit: 15)
    rescue SpotifyClient::Error => e
        flash[:alert] = "Failed to fetch recommendations: #{e.message}"
        @recommendations = []
    end

end