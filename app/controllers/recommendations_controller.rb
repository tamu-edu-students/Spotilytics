class RecommendationsController < ApplicationController
    before_action :require_spotify_auth!

    def recommendations
        spotify_client = SpotifyClient.new(session: session)

        top_artists = spotify_client.top_artists(limit: 20, time_range: "medium_term")
        top_tracks  = spotify_client.top_tracks(limit: 20, time_range: "medium_term")

        # Combine and randomly select 5 total seeds
        sampled_seeds = (top_artists.map(&:name) + top_tracks.map(&:name)).sample(5)

        # Build query for Spotify Search
        search_queries = sampled_seeds.join(" OR ")

        @recommendations = spotify_client.search_tracks(search_queries, limit: 15)
    rescue SpotifyClient::UnauthorizedError
        redirect_to home_path, alert: "You must log in with spotify to view your recommendations." and return
    rescue SpotifyClient::Error => e
        flash[:alert] = "Failed to fetch recommendations: #{e.message}"
        @recommendations = []
    end
end
