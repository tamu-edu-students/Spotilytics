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

    def stub_spotify_put(path, body:, status: 200)
        stub_request(:put, %r{https://api.spotify.com/v1#{path}})
            .to_return(status: status, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_spotify_delete(path, body:, status: 200)
        stub_request(:delete, %r{https://api.spotify.com/v1#{path}})
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
            id: "u123", display_name: "Test", images: [ { "url" => "img.jpg" } ],
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
            expect(client.add_tracks_to_playlist(playlist_id: "p123", uris: [ "spotify:track:1" ])).to be true
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

    describe "#search_tracks" do
        let(:query) { "Daft Punk" }
        let(:limit) { 10 }
        let(:base_url) { "https://api.spotify.com/v1" }
        let(:url) { "#{base_url}/search?q=#{CGI.escape(query)}&type=track&limit=#{limit}" }

        context "when the request succeeds with track data" do
            let(:body) do
                {
                tracks: {
                    items: [
                    {
                        "id" => "track123",
                        "name" => "Harder, Better, Faster, Stronger",
                        "artists" => [ { "name" => "Daft Punk" } ],
                        "album" => {
                        "name" => "Discovery",
                        "images" => [ { "url" => "http://example.com/discovery.jpg" } ]
                        },
                        "popularity" => 95,
                        "preview_url" => "http://example.com/preview.mp3",
                        "external_urls" => { "spotify" => "https://open.spotify.com/track/track123" },
                        "duration_ms" => 224000
                    }
                    ]
                }
                }
            end


            before do
                stub_request(:get, "#{base_url}/search")
                .with(query: hash_including(q: query, type: "track", limit: limit.to_s))
                .to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

                stub_spotify_get("/me", body: { id: "user123" })
            end

            it "returns an array of OpenStruct track objects" do
                results = client.search_tracks(query, limit: limit)

                expect(results).to be_an(Array)
                expect(results.size).to eq(1)

                track = results.first
                expect(track.id).to eq("track123")
                expect(track.name).to eq("Harder, Better, Faster, Stronger")
                expect(track.artists).to eq("Daft Punk")
                expect(track.album_name).to eq("Discovery")
                expect(track.album_image_url).to eq("http://example.com/discovery.jpg")
                expect(track.popularity).to eq(95)
                expect(track.preview_url).to eq("http://example.com/preview.mp3")
                expect(track.spotify_url).to eq("https://open.spotify.com/track/track123")
                expect(track.duration_ms).to eq(224000)
            end
        end

        context "when Spotify returns no items" do
            before do
                stub_spotify_get(
                    "/search",
                    body: { tracks: { items: [] } }
                )

                stub_spotify_get("/me", body: { id: "user123" })
            end

            it "returns an empty array" do
                results = client.search_tracks(query)
                expect(results).to eq([])
            end
        end

        context "when Spotify response is missing 'tracks' key" do
            before do
                stub_spotify_get(
                    "/search",
                    body: {}
                )

                stub_spotify_get("/me", body: { id: "user123" })
            end

            it "returns an empty array safely" do
                results = client.search_tracks(query)
                expect(results).to eq([])
            end
        end

        context "when get raises an error" do
            before do
                allow(client).to receive(:get).and_raise(SpotifyClient::Error, "API failed")
            end

            it "raises SpotifyClient::Error" do
                expect { client.search_tracks(query) }.to raise_error(SpotifyClient::Error, /API failed/)
            end
        end

        context "when ensure_access_token! raises UnauthorizedError" do
            before do
                allow(client).to receive(:ensure_access_token!).and_raise(SpotifyClient::UnauthorizedError)
            end

            it "raises UnauthorizedError and does not call get" do
                expect(client).not_to receive(:get)
                expect { client.search_tracks(query) }.to raise_error(SpotifyClient::UnauthorizedError)
            end
        end
    end

    describe "#top_artists" do
        let(:limit) { 10 }
        let(:time_range) { "long_term" }

        before do
            # Stub /me for cache_for → current_user_id
            stub_spotify_get("/me", body: { id: "user123" })

            # Disable actual caching for testing
            allow(client).to receive(:cache_for).and_wrap_original { |_m, *_args, &block| block.call }

            # Mock access token retrieval
            allow(client).to receive(:ensure_access_token!).and_return("valid_token")
        end

        context "when the request succeeds with artist data" do
            let(:body) do
            {
                items: Array.new(limit) do |i|
                {
                    "id" => "artist#{i + 1}",
                    "name" => "Artist #{i + 1}",
                    "images" => [ { "url" => "http://example.com/artist#{i + 1}.jpg" } ],
                    "genres" => [ "genre#{i + 1}" ],
                    "popularity" => 100 - i
                }
                end
            }
            end

            before do
                stub_spotify_get("/me/top/artists", body: body)
            end

            it "returns an array of OpenStruct artist objects with correct rank and data" do
                results = client.top_artists(limit: limit, time_range: time_range)
                expect(results.size).to eq(limit)

                results.each_with_index do |artist, i|
                    expect(artist.id).to eq("artist#{i + 1}")
                    expect(artist.name).to eq("Artist #{i + 1}")
                    expect(artist.rank).to eq(i + 1)
                    expect(artist.image_url).to eq("http://example.com/artist#{i + 1}.jpg")
                    expect(artist.genres).to eq([ "genre#{i + 1}" ])
                    expect(artist.popularity).to eq(100 - i)
                    expect(artist.playcount).to eq(100 - i)
                end
            end
        end

        context "when Spotify returns no items" do
            before do
                stub_spotify_get("/me/top/artists", body: { items: [] })
            end

            it "returns an empty array" do
                expect(client.top_artists(limit: limit, time_range: time_range)).to eq([])
            end
        end

        context "when Spotify response is missing 'items' key" do
            before do
                stub_spotify_get("/me/top/artists", body: {})
            end

            it "returns an empty array safely" do
                expect(client.top_artists(limit: limit, time_range: time_range)).to eq([])
            end
        end

        context "when get raises an error" do
            before do
                allow(client).to receive(:get).and_raise(SpotifyClient::Error, "API failed")
            end

            it "raises SpotifyClient::Error" do
                expect { client.top_artists(limit: limit, time_range: time_range) }.to raise_error(SpotifyClient::Error, /API failed/)
            end
        end

        context "when ensure_access_token! raises UnauthorizedError" do
            before do
                allow(client).to receive(:ensure_access_token!).and_raise(SpotifyClient::UnauthorizedError)
            end

            it "raises UnauthorizedError and does not call get" do
                expect(client).not_to receive(:get)
                expect { client.top_artists(limit: limit, time_range: time_range) }.to raise_error(SpotifyClient::UnauthorizedError)
            end
        end
    end

    describe '#follow_artists' do
        let(:access_token) { "valid_token" }

        before do
            allow(client).to receive(:ensure_access_token!).and_return(access_token)
            allow(client).to receive(:cache_for).and_wrap_original { |_m, *_args, &block| block.call }
            stub_spotify_get("/me", body: { id: "user123" })
        end

        context "when given a single artist ID" do
            it "sends a PUT request to follow the artist and returns true" do
            stub_request(:put, "https://api.spotify.com/v1/me/following")
                .with(
                query: { type: "artist" },
                body: { ids: ["abc123"] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.follow_artists("abc123")
            expect(result).to eq(true)
            end
        end

        context "when given multiple artist IDs with duplicates and integers" do
            it "removes duplicates, stringifies IDs, and sends them correctly" do
            stub_request(:put, "https://api.spotify.com/v1/me/following")
                .with(
                query: { type: "artist" },
                body: { ids: ["123", "456"] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.follow_artists([123, "456", 123])
            expect(result).to eq(true)
            end
        end

        context "when given an empty array" do
            it "returns true without making any HTTP request" do
            expect(client).not_to receive(:request_with_json)
            expect(client.follow_artists([])).to eq(true)
            end
        end

        context "when the request fails with an error" do
            it "raises SpotifyClient::Error" do
            stub_request(:put, "https://api.spotify.com/v1/me/following")
                .with(query: { type: "artist" })
                .to_return(status: 400, body: { error: { message: "Bad Request" } }.to_json)

            expect {
                client.follow_artists("abc123")
            }.to raise_error(SpotifyClient::Error, /Bad Request/)
            end
        end
    end

    describe "#unfollow_artists" do
        let(:access_token) { "valid_token" }

        before do
            allow(client).to receive(:ensure_access_token!).and_return(access_token)
            allow(client).to receive(:cache_for).and_wrap_original { |_m, *_args, &block| block.call }
            # Some Spotify endpoints may call /me for caching logic, so stub it to be safe
            stub_spotify_get("/me", body: { id: "user123" })
        end

        context "when given a single artist ID" do
            it "sends a DELETE request to unfollow the artist and returns true" do
            stub_request(:delete, "https://api.spotify.com/v1/me/following")
                .with(
                query: { type: "artist" },
                body: { ids: ["abc123"] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.unfollow_artists("abc123")
            expect(result).to eq(true)
            end
        end

        context "when given multiple artist IDs with duplicates and integers" do
            it "removes duplicates, stringifies IDs, and sends them correctly" do
            stub_request(:delete, "https://api.spotify.com/v1/me/following")
                .with(
                query: { type: "artist" },
                body: { ids: ["123", "456"] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.unfollow_artists([123, "456", 123])
            expect(result).to eq(true)
            end
        end

        context "when given an empty array" do
            it "returns true without making any HTTP request" do
            expect(client).not_to receive(:request_with_json)
            expect(client.unfollow_artists([])).to eq(true)
            end
        end

        context "when the request fails with an error" do
            it "raises SpotifyClient::Error" do
            stub_request(:delete, "https://api.spotify.com/v1/me/following")
                .with(query: { type: "artist" })
                .to_return(status: 400, body: { error: { message: "Bad Request" } }.to_json)

            expect {
                client.unfollow_artists("abc123")
            }.to raise_error(SpotifyClient::Error, /Bad Request/)
            end
        end
    end

    describe "#followed_artist_ids" do
        let(:access_token) { "valid_token" }

        before do
            allow(client).to receive(:ensure_access_token!).and_return(access_token)
            allow(client).to receive(:cache_for).and_wrap_original { |_m, *_args, &block| block.call }
            stub_spotify_get("/me", body: { id: "user123" }) 
        end

        context "when given an empty array" do
            it "returns an empty Set and does not call the API" do
            expect(client).not_to receive(:get)
            result = client.followed_artist_ids([])
            expect(result).to eq(Set.new)
            end
        end

        context "when given a single ID that is followed" do
            it "returns a Set containing that ID" do
            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: "abc123" })
                .to_return(status: 200, body: "[true]", headers: { "Content-Type" => "application/json" })

            result = client.followed_artist_ids("abc123")
            expect(result).to eq(Set.new(["abc123"]))
            end
        end

        context "when given a single ID that is not followed" do
            it "returns an empty Set" do
            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: "abc123" })
                .to_return(status: 200, body: "[false]", headers: { "Content-Type" => "application/json" })

            result = client.followed_artist_ids("abc123")
            expect(result).to eq(Set.new)
            end
        end

        context "when given multiple IDs with duplicates and mixed statuses" do
            it "deduplicates IDs and includes only followed ones" do
            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: "1,2,3" })
                .to_return(status: 200, body: "[true,false,true]", headers: { "Content-Type" => "application/json" })

            result = client.followed_artist_ids(["1", "2", "3", "1"])
            expect(result).to eq(Set.new(["1", "3"]))
            end
        end

        context "when given more than 50 IDs" do
            it "splits them into batches of 50 per request" do
            ids = (1..60).to_a.map(&:to_s)
            first_batch = ids[0...50]
            second_batch = ids[50..]

            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: first_batch.join(",") })
                .to_return(status: 200, body: "[#{(['true'] * 50).join(',')}]", headers: { "Content-Type" => "application/json" })

            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: second_batch.join(",") })
                .to_return(status: 200, body: "[true,true,true,true,true,true,true,true,true,true]", headers: { "Content-Type" => "application/json" })

            result = client.followed_artist_ids(ids)
            expect(result.size).to eq(60)
            expect(result).to include(*ids)
            end
        end
    end

end
