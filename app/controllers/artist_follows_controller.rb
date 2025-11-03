class ArtistFollowsController < ApplicationController
  before_action :require_spotify_auth!

  def create
    spotify_id = params.require(:spotify_id)

    spotify_client.follow_artists([spotify_id])
    redirect_back fallback_location: top_artists_path, notice: 'Artist followed.'
  rescue SpotifyClient::UnauthorizedError
    redirect_to login_path, alert: 'Please sign in with Spotify to continue.'
  rescue SpotifyClient::Error => e
    redirect_back fallback_location: top_artists_path, alert: "Unable to follow artist: #{e.message}"
  end

  def destroy
    spotify_id = params[:spotify_id]
    raise ActionController::ParameterMissing, :spotify_id if spotify_id.blank?

    spotify_client.unfollow_artists([spotify_id])
    redirect_back fallback_location: top_artists_path, notice: 'Artist unfollowed.'
  rescue SpotifyClient::UnauthorizedError
    redirect_to login_path, alert: 'Please sign in with Spotify to continue.'
  rescue SpotifyClient::Error => e
    redirect_back fallback_location: top_artists_path, alert: "Unable to unfollow artist: #{e.message}"
  end

  private

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end
end
