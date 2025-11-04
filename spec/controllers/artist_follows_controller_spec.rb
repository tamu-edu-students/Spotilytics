require "rails_helper"
require "set"

RSpec.describe ArtistFollowsController, type: :controller do
    shared_context "logged in user" do
        let(:session_user) do
        {
            "display_name" => "Test Listener",
            "email"        => "listener@example.com",
            "image"        => "http://example.com/user.jpg"
        }
        end

        before { session[:spotify_user] = session_user }
    end
    include_context "logged in user"

    let(:spotify_client) { instance_double(SpotifyClient) }
    let(:spotify_id) { "artist123" }

    before do
        # Simulate a valid Spotify session
        session[:spotify_token] = "valid_token"
        session[:spotify_refresh_token] = "refresh_token"
        session[:spotify_expires_at] = 1.hour.from_now.to_i

        allow(controller).to receive(:spotify_client).and_return(spotify_client)
    end

    describe "#create" do
        context "when follow succeeds" do
            before do
                allow(spotify_client).to receive(:follow_artists).with([spotify_id]).and_return(true)
            end

            it "follows the artist and redirects back with notice" do
                request.env["HTTP_REFERER"] = "/previous_page"
                post :create, params: { spotify_id: spotify_id }

                expect(response).to redirect_to("/previous_page")
                expect(flash[:notice]).to eq("Artist followed.")
            end

            it "redirects to top_artists_path if no referrer" do
                post :create, params: { spotify_id: spotify_id }
                expect(response).to redirect_to(top_artists_path)
            end
        end

        context "when SpotifyClient::UnauthorizedError occurs" do
            before do
                allow(spotify_client).to receive(:follow_artists)
                .and_raise(SpotifyClient::UnauthorizedError.new("bad token"))
            end

            it "redirects to login_path with an alert" do
                post :create, params: { spotify_id: spotify_id }
                expect(response).to redirect_to(login_path)
                expect(flash[:alert]).to match(/please sign in/i)
            end
        end

        context "when SpotifyClient::Error with insufficient scope occurs" do
            before do
                allow(spotify_client).to receive(:follow_artists)
                .and_raise(SpotifyClient::Error.new("insufficient client scope"))
            end

            it "resets session and redirects to login_path" do
                post :create, params: { spotify_id: spotify_id }

                expect(response).to redirect_to(login_path)
                expect(flash[:alert]).to match(/needs permission/)
                expect(session[:spotify_token]).to be_nil
                expect(session[:spotify_refresh_token]).to be_nil
            end
        end

        context "when SpotifyClient::Error occurs for another reason" do
            before do
                allow(spotify_client).to receive(:follow_artists)
                .and_raise(SpotifyClient::Error.new("API rate limit exceeded"))
            end

            it "redirects back with a general alert message" do
                request.env["HTTP_REFERER"] = "/dashboard"
                post :create, params: { spotify_id: spotify_id }

                expect(response).to redirect_to("/dashboard")
                expect(flash[:alert]).to match(/Unable to follow artist: API rate limit exceeded/)
            end
        end
    end

  # ---------------------------------------------------------------------------
    describe "#destroy" do
        context "when unfollow succeeds" do
            before do
                allow(spotify_client).to receive(:unfollow_artists).with([spotify_id]).and_return(true)
            end

            it "unfollows the artist and redirects back with notice" do
                request.env["HTTP_REFERER"] = "/previous_page"
                delete :destroy, params: { spotify_id: spotify_id }

                expect(response).to redirect_to("/previous_page")
                expect(flash[:notice]).to eq("Artist unfollowed.")
            end
        end

        context "when SpotifyClient::UnauthorizedError occurs" do
            before do
                allow(spotify_client).to receive(:unfollow_artists)
                .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))
            end

            it "redirects to login_path with alert" do
                delete :destroy, params: { spotify_id: spotify_id }

                expect(response).to redirect_to(login_path)
                expect(flash[:alert]).to match(/please sign in/i)
            end
        end

        context "when SpotifyClient::Error with insufficient scope occurs" do
            before do
                allow(spotify_client).to receive(:unfollow_artists)
                .and_raise(SpotifyClient::Error.new("insufficient client scope"))
            end

            it "resets session and redirects to login_path" do
                delete :destroy, params: { spotify_id: spotify_id }

                expect(response).to redirect_to(login_path)
                expect(flash[:alert]).to match(/needs permission/)
                expect(session[:spotify_token]).to be_nil
                expect(session[:spotify_refresh_token]).to be_nil
            end
        end

        context "when SpotifyClient::Error occurs for another reason" do
            before do
                allow(spotify_client).to receive(:unfollow_artists)
                .and_raise(SpotifyClient::Error.new("Spotify API down"))
            end

            it "redirects back with alert message" do
                request.env["HTTP_REFERER"] = "/profile"
                delete :destroy, params: { spotify_id: spotify_id }

                expect(response).to redirect_to("/profile")
                expect(flash[:alert]).to match(/Unable to unfollow artist: Spotify API down/)
            end
        end
    end
end