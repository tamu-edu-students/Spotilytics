class SessionsController < ApplicationController
    def create
        auth = request.env['omniauth.auth']
        info = auth['info'] || {}

        session[:spotify_user] = {
            display_name: info['name'],
            email:        info['email'],
            image:        info['image'],
        }

        credentials = auth['credentials'] || {}
        session[:spotify_token]         = credentials['token']
        session[:spotify_refresh_token] = credentials['refresh_token']
        session[:spotify_expires_at]    = credentials['expires_at']

        redirect_to root_path, notice: "Signed in with Spotify"
    end

    def destroy
        reset_session
        redirect_to root_path, notice: "Signed out"
    end

    def failure
        reset_session
        error_message = "Spotify login failed."
        redirect_to root_path, alert: "Authentication error: #{error_message}"
    end
end