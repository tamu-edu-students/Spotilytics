class ReccomendationsController < ApplicationController
    before_action :require_spotify_auth!

    def reccomendations
        client = SpotifyClient.new(session: session)
    end
end