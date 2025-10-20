# spec/requests/sessions_spec.rb
require "rails_helper"

RSpec.describe "Spotify auth", type: :request do
  describe "GET /auth/spotify/callback" do
    it "stores the user and tokens in session and redirects home with notice" do
      get "/auth/spotify/callback"

      expect(session[:spotify_user]).to include(
        display_name: "Test User",
        email: "test-user@example.com",
        image: "https://pics.example/avatar.png"
      )

      expect(session[:spotify_token]).to         eq("access-token-1")
      expect(session[:spotify_refresh_token]).to eq("refresh-token-1")
      expect(session[:spotify_expires_at]).to    be_present

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Signed in with Spotify")
    end

    it "gracefully handles missing pieces in the auth hash" do
      OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
        provider: "spotify",
        uid: "no-info",
        info: {},
        credentials: {}
      )

      get "/auth/spotify/callback"

      expect(session[:spotify_user]).to be_present
      expect(session[:spotify_user][:display_name]).to be_nil
      expect(session[:spotify_token]).to be_nil

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /auth/failure" do
    it "redirects home and shows a friendly message" do
      get "/auth/failure", params: { message: "invalid_credentials" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Spotify login failed.")
    end
  end

  describe "DELETE /logout" do
    before do
      get "/auth/spotify/callback"
      expect(session[:spotify_user]).to be_present
    end

    it "clears all session keys and redirects home" do
      delete "/logout"
      expect(session[:spotify_user]).to be_nil
      expect(session[:spotify_token]).to be_nil
      expect(session[:spotify_refresh_token]).to be_nil
      expect(session[:spotify_expires_at]).to be_nil

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Signed out")
    end
  end
end