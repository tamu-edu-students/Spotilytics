class ArtistFollowsController < ApplicationController
  before_action :require_spotify_auth!

  def create
    spotify_id = params.require(:spotify_id)

    spotify_client.follow_artists([spotify_id])
    redirect_back fallback_location: top_artists_path, notice: 'Artist followed.'
  rescue SpotifyClient::UnauthorizedError
    redirect_to login_path, alert: 'Please sign in with Spotify to continue.'
  rescue SpotifyClient::Error => e
    handle_follow_error(e, action: :follow)
  end

  def destroy
    spotify_id = params[:spotify_id]
    raise ActionController::ParameterMissing, :spotify_id if spotify_id.blank?

    spotify_client.unfollow_artists([spotify_id])
    redirect_back fallback_location: top_artists_path, notice: 'Artist unfollowed.'
  rescue SpotifyClient::UnauthorizedError
    redirect_to login_path, alert: 'Please sign in with Spotify to continue.'
  rescue SpotifyClient::Error => e
    handle_follow_error(e, action: :unfollow)
  end

  private

  def spotify_client
    @spotify_client ||= SpotifyClient.new(session: session)
  end

  def handle_follow_error(error, action:)
    if insufficient_scope?(error)
      reset_spotify_session!
      redirect_to login_path, alert: 'Spotify now needs permission to manage your follows. Please sign in again.'
    else
      redirect_back fallback_location: top_artists_path,
                    alert: "Unable to #{action} artist: #{error.message}"
    end
  end

  def insufficient_scope?(error)
    error.message.to_s.downcase.include?('insufficient client scope')
  end

  def reset_spotify_session!
    session.delete(:spotify_token)
    session.delete(:spotify_refresh_token)
    session.delete(:spotify_expires_at)
  end
end
