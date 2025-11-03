require "rails_helper"

RSpec.describe SpotifyClient, type: :service do
    let(:session) do
        {
        spotify_token: "valid_token",
        spotify_expires_at: 1.hour.from_now.to_i,
        spotify_refresh_token: "refresh123"
        }.with_indifferent_access
    end

    subject(:client) { described_class.new(session: session) }

    before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return("client_id")
        allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_SECRET").and_return("client_secret")
    end

    def stub_spotify_get(path, body:, status: 200)
        stub_request(:get, %r{https://api.spotify.com/v1#{path}})
            .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_spotify_post(path, body:, status: 200)
        stub_request(:post, %r{https://api.spotify.com/v1#{path}})
            .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    describe "#ensure_access_token!" do
        it "returns the existing token if valid" do
            expect(client.send(:ensure_access_token!)).to eq("valid_token")
        end

        it "refreshes the token if expired" do
            session[:spotify_expires_at] = 1.minute.ago.to_i
            allow(client).to receive(:refresh_access_token!).and_return("new_token")
            expect(client.send(:ensure_access_token!)).to eq("new_token")
        end
    end

    describe "#token_expired?" do
        it "returns true if expires_at is missing" do
            session.delete(:spotify_expires_at)
            expect(client.send(:token_expired?)).to be true
        end

        it "returns false if token is still valid" do
            session[:spotify_expires_at] = 1.hour.from_now.to_i
            expect(client.send(:token_expired?)).to be false
        end
    end

    describe "#refresh_access_token!" do
        let(:token_uri) { described_class::TOKEN_URI }

        it "raises UnauthorizedError if refresh token missing" do
            session.delete(:spotify_refresh_token)
            expect { client.send(:refresh_access_token!) }.to raise_error(SpotifyClient::UnauthorizedError)
        end

        it "raises UnauthorizedError if credentials missing" do
            allow(ENV).to receive(:[]).with("SPOTIFY_CLIENT_ID").and_return(nil)
            expect { client.send(:refresh_access_token!) }.to raise_error(SpotifyClient::UnauthorizedError)
        end

        it "refreshes successfully" do
            body = { "access_token" => "newtoken", "expires_in" => 3600 }
            stub_request(:post, token_uri.to_s).to_return(status: 200, body: body.to_json)
            expect(client.send(:refresh_access_token!)).to eq("newtoken")
            expect(session[:spotify_token]).to eq("newtoken")
        end

        it "raises UnauthorizedError on invalid response" do
            body = { "error" => { "message" => "bad token" } }
            stub_request(:post, token_uri.to_s).to_return(status: 400, body: body.to_json)
            expect { client.send(:refresh_access_token!) }.to raise_error(SpotifyClient::Error, "bad token")
        end
    end

    describe "#get" do
        it "returns parsed JSON" do
            stub_spotify_get("/me", body: { id: "123" })
            result = client.send(:get, "/me", "token")
            expect(result["id"]).to eq("123")
        end

        it "raises Error on bad response" do
            stub_spotify_get("/me", body: { error: { message: "oops" } }, status: 400)
            expect { client.send(:get, "/me", "token") }.to raise_error(SpotifyClient::Error)
        end
    end

    describe "#parse_json" do
        it "returns {} on invalid JSON" do
            expect(client.send(:parse_json, "invalid")).to eq({})
        end
    end

    describe "#profile" do
        it "returns an OpenStruct with user data" do
            allow(client).to receive(:current_user_id).and_return("u123")
            stub_spotify_get("/users/u123", body: {
            id: "u123", display_name: "Test", images: [{ "url" => "img.jpg" }],
            followers: { "total" => 10 }, external_urls: { "spotify" => "url" }
            })
            profile = client.profile
            expect(profile.display_name).to eq("Test")
            expect(profile.followers).to eq(10)
        end
    end

    describe "#create_playlist_for" do
        it "returns new playlist id" do
            stub_spotify_post("/users/uid/playlists", body: { id: "playlist123" })
            result = client.create_playlist_for(user_id: "uid", name: "test", description: "desc", public: true)
            expect(result).to eq("playlist123")
        end

        it "raises Error if no id returned" do
            stub_spotify_post("/users/uid/playlists", body: {})
            expect {
            client.create_playlist_for(user_id: "uid", name: "test", description: "desc")
            }.to raise_error(SpotifyClient::Error)
        end
    end

    describe "#add_tracks_to_playlist" do
        it "adds tracks successfully" do
            stub_spotify_post("/playlists/p123/tracks", body: {})
            expect(client.add_tracks_to_playlist(playlist_id: "p123", uris: ["spotify:track:1"])).to be true
        end
    end

    describe "#clear_user_cache" do
        it "deletes cache keys for the user" do
            allow(client).to receive(:current_user_id).and_return("u123")
            expect(Rails.cache).to receive(:delete_matched).with("spotify_u123_*")
            client.clear_user_cache
        end
    end

    describe "#token_headers" do
        it "encodes client_id and secret in base64" do
            headers = client.send(:token_headers)
            expect(headers["Authorization"]).to include("Basic")
        end
    end
end
