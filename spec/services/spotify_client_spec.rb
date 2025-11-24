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

  describe "#recently_played" do
    let(:now) { Time.utc(2025, 1, 1, 12, 0, 0) }

    before do
      allow(Time).to receive(:iso8601).and_call_original
      stub_spotify_get("/me", body: { id: "user123" })

      allow(client).to receive(:cache_for).and_wrap_original { |_m, *_args, &block| block.call }
      allow(client).to receive(:ensure_access_token!).and_return("valid_token")
      allow(client).to receive(:current_user_id).and_return("user123")
    end

    it "paginates until the requested limit is reached" do
      first_batch_time = now
      second_batch_time = now - 1.hour

      first_items = Array.new(50) do |i|
        {
          "played_at" => (first_batch_time - i.minutes).iso8601,
          "track" => { "id" => "t#{i}", "name" => "Track #{i}" }
        }
      end

      second_items = Array.new(50) do |i|
        {
          "played_at" => (second_batch_time - i.minutes).iso8601,
          "track" => { "id" => "t#{50 + i}", "name" => "Track #{50 + i}" }
        }
      end

      before_cursor = ((first_items.last["played_at"].to_time.to_f * 1000).to_i) - 1

      expect(client).to receive(:get)
        .with("/me/player/recently-played", "valid_token", hash_including(limit: 50))
        .and_return({ "items" => first_items, "next" => "next-page" })

      expect(client).to receive(:get)
        .with("/me/player/recently-played", "valid_token", hash_including(limit: 50, before: before_cursor))
        .and_return({ "items" => second_items, "next" => nil })

      results = client.recently_played(limit: 100)
      expect(results.size).to eq(100)
      expect(results.first.id).to eq("t0")
      expect(results.last.id).to eq("t99")
    end

    it "deduplicates repeated plays and stops when a short page is returned" do
      timestamp = now.iso8601
      dup_item = { "played_at" => timestamp, "track" => { "id" => "dup", "name" => "Dup" } }
      final_item = { "played_at" => (now - 2.minutes).iso8601, "track" => { "id" => "keep", "name" => "Keep" } }

      allow(client).to receive(:get).and_return(
        { "items" => Array.new(50, dup_item) },
        { "items" => [ final_item ] } # short page ends pagination
      )

      results = client.recently_played(limit: 50)
      expect(results.map(&:id)).to eq([ "dup", "keep" ])
    end

    it "returns an empty array when Spotify returns nothing" do
      allow(client).to receive(:get).and_return({ "items" => [] })
      expect(client.recently_played(limit: 25)).to eq([])
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

    describe "#search_tracks DB persistence" do
        let(:query) { "Hass Hass" }
        let(:limit) { 5 }
        let(:user_id) { "user123" }

        let(:api_items) do
        [
            {
            "id" => "t1",
            "name" => "Song 1",
            "artists" => [ { "name" => "Artist 1" } ],
            "album" => { "name" => "Album 1", "images" => [ { "url" => "img1.jpg" } ] },
            "popularity" => 80,
            "preview_url" => "preview1",
            "external_urls" => { "spotify" => "spotify://t1" },
            "duration_ms" => 180_000
            },
            {
            "id" => "t2",
            "name" => "Song 2",
            "artists" => [ { "name" => "Artist 2" } ],
            "album" => { "name" => "Album 2", "images" => [ { "url" => "img2.jpg" } ] },
            "popularity" => 90,
            "preview_url" => "preview2",
            "external_urls" => { "spotify" => "spotify://t2" },
            "duration_ms" => 200_000
            }
        ]
        end

        before do
            session[:spotify_user] = { "id" => user_id }
            allow(client).to receive(:current_user_id).and_return(user_id)
            allow(client).to receive(:ensure_access_token!).and_return("token")
        end

        it "creates TrackSearch + TrackSearchResults when no fresh record exists" do
        stub_spotify_get("/search", body: { tracks: { items: api_items } })
        stub_spotify_get("/me", body: { id: user_id })

        expect {
            results = client.search_tracks(query, limit: limit)
            expect(results.map(&:id)).to match_array(%w[t1 t2])
        }.to change(TrackSearch, :count).by(1)
        .and change(TrackSearchResult, :count).by(2)

        search = TrackSearch.last
        expect(search.spotify_user_id).to eq(user_id)
        expect(search.query).to eq(query)
        expect(search.limit).to eq(limit)
        expect(search.track_search_results.order(:position).pluck(:spotify_id)).to eq(%w[t1 t2])
        end

        it "reuses a fresh TrackSearch from DB and does not hit the API" do
        search = TrackSearch.create!(
            spotify_user_id: user_id,
            query:           query,
            limit:           limit,
            fetched_at:      Time.current
        )

        TrackSearchResult.create!(
            track_search: search,
            position:     1,
            spotify_id:   "cached-track",
            name:         "Cached Song"
        )

        expect(client).not_to receive(:get).with("/search", anything, anything)

        results = client.search_tracks(query, limit: limit)
        expect(results.map(&:id)).to eq([ "cached-track" ])
        end

        it "treats old TrackSearch (older than max_age) as stale and refetches" do
        old = TrackSearch.create!(
            spotify_user_id: user_id,
            query:           query,
            limit:           limit,
            fetched_at:      8.days.ago
        )
        TrackSearchResult.create!(
            track_search: old,
            position:     1,
            spotify_id:   "old-track",
            name:         "Old Song"
        )

        stub_spotify_get("/search", body: { tracks: { items: api_items } })
        stub_spotify_get("/me", body: { id: user_id })

        expect {
            client.search_tracks(query, limit: limit)
        }.to change(TrackSearch, :count).by(1)
        end
    end

    describe "#top_artists DB persistence" do
        let(:limit) { 3 }
        let(:time_range) { "long_term" }
        let(:user_id) { "user123" }

        let(:api_items) do
        (1..limit).map do |i|
            {
            "id" => "artist#{i}",
            "name" => "Artist #{i}",
            "images" => [ { "url" => "img#{i}.jpg" } ],
            "genres" => [ "g#{i}" ],
            "popularity" => 90 + i
            }
        end
        end

        before do
            session[:spotify_user] = { "id" => user_id }
            allow(client).to receive(:current_user_id).and_return(user_id)
            allow(client).to receive(:ensure_access_token!).and_return("token")
        end

        it "creates a TopArtistBatch and TopArtistResult records when empty" do
        stub_spotify_get("/me", body: { id: user_id })
        stub_spotify_get("/me/top/artists", body: { items: api_items })

        expect {
            results = client.top_artists(limit: limit, time_range: time_range)
            expect(results.size).to eq(limit)
        }.to change(TopArtistBatch, :count).by(1)
        .and change(TopArtistResult, :count).by(limit)

        batch = TopArtistBatch.last
        expect(batch.spotify_user_id).to eq(user_id)
        expect(batch.limit).to eq(limit)
        expect(batch.time_range).to eq(time_range)

        expect(batch.top_artist_results.order(:position).pluck(:spotify_id)).to eq(%w[artist1 artist2 artist3])
        end

        it "reuses a fresh TopArtistBatch and does not hit the API" do
        batch = TopArtistBatch.create!(
            spotify_user_id: user_id,
            time_range:      time_range,
            limit:           limit,
            fetched_at:      Time.current
        )
        TopArtistResult.create!(
            top_artist_batch: batch,
            position:         1,
            spotify_id:       "cached-artist",
            name:             "Cached"
        )

        expect(client).not_to receive(:get).with("/me/top/artists", anything, anything)

        results = client.top_artists(limit: limit, time_range: time_range)
        expect(results.map(&:id)).to eq([ "cached-artist" ])
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
                body: { ids: [ "abc123" ] }.to_json,
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
                body: { ids: [ "123", "456" ] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.follow_artists([ 123, "456", 123 ])
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

    describe "#top_tracks DB persistence" do
        let(:limit) { 3 }
        let(:time_range) { "medium_term" }
        let(:user_id) { "user123" }

        let(:api_items) do
        (1..limit).map do |i|
            {
            "id" => "track#{i}",
            "name" => "Track #{i}",
            "artists" => [ { "name" => "Artist #{i}" } ],
            "album" => { "name" => "Album #{i}", "images" => [ { "url" => "img#{i}.jpg" } ] },
            "popularity" => 70 + i,
            "preview_url" => "preview#{i}",
            "external_urls" => { "spotify" => "spotify://track#{i}" },
            "duration_ms" => 200_000 + i
            }
        end
        end

        before do
            session[:spotify_user] = { "id" => user_id }
            allow(client).to receive(:current_user_id).and_return(user_id)
            allow(client).to receive(:ensure_access_token!).and_return("token")
        end

        it "creates a TopTrackBatch and TopTrack records when empty" do
        stub_spotify_get("/me", body: { id: user_id })
        stub_spotify_get("/me/top/tracks", body: { items: api_items })

        expect {
            results = client.top_tracks(limit: limit, time_range: time_range)
            expect(results.size).to eq(limit)
        }.to change(TopTrackBatch, :count).by(1)
        .and change(TopTrackResult, :count).by(limit)

        batch = TopTrackBatch.last
        expect(batch.spotify_user_id).to eq(user_id)
        expect(batch.limit).to eq(limit)
        expect(batch.time_range).to eq(time_range)
        expect(batch.top_track_results.order(:position).pluck(:spotify_id)).to eq(%w[track1 track2 track3])
        end

        it "reuses a fresh TopTrackBatch and does not hit the API" do
        batch = TopTrackBatch.create!(
            spotify_user_id: user_id,
            time_range:      time_range,
            limit:           limit,
            fetched_at:      Time.current
        )
        TopTrackResult.create!(
            top_track_batch: batch,
            position:        1,
            spotify_id:      "cached-track",
            name:            "Cached track"
        )

        expect(client).not_to receive(:get).with("/me/top/tracks", anything, anything)

        results = client.top_tracks(limit: limit, time_range: time_range)
        expect(results.map(&:id)).to eq([ "cached-track" ])
        end
    end

    describe "#new_releases DB persistence" do
        let(:limit) { 4 }
        let(:user_id) { "user123" }

        let(:api_items) do
        (1..limit).map do |i|
            {
            "id" => "album#{i}",
            "name" => "Album #{i}",
            "images" => [ { "url" => "img#{i}.jpg" } ],
            "total_tracks" => i,
            "release_date" => "2025-01-0#{i}",
            "external_urls" => { "spotify" => "spotify://album#{i}" },
            "artists" => [ { "name" => "Artist #{i}" } ]
            }
        end
        end

        before do
            session[:spotify_user] = { "id" => user_id }
            allow(client).to receive(:current_user_id).and_return(user_id)
            allow(client).to receive(:ensure_access_token!).and_return("token")
        end

        it "creates a NewReleaseBatch + NewRelease records when empty" do
        stub_spotify_get("/browse/new-releases", body: { albums: { items: api_items } })
        stub_spotify_get("/me", body: { id: user_id })

        expect {
            results = client.new_releases(limit: limit)
            expect(results.size).to eq(limit)
        }.to change(NewReleaseBatch, :count).by(1)
        .and change(NewRelease, :count).by(limit)

        batch = NewReleaseBatch.last
        expect(batch.limit).to eq(limit)
        expect(batch.new_releases.order(:position).pluck(:spotify_id)).to eq(%w[album1 album2 album3 album4])
        end

        it "reuses a fresh NewReleaseBatch and does not hit the API" do
        batch = NewReleaseBatch.create!(
            limit:           limit,
            fetched_at:      Time.current
        )
        NewRelease.create!(
            new_release_batch: batch,
            position:          1,
            spotify_id:        "cached-album",
            name:              "Cached Album"
        )

        expect(client).not_to receive(:get).with("/browse/new-releases", anything, anything)

        results = client.new_releases(limit: limit)
        expect(results.map(&:id)).to eq([ "cached-album" ])
        end
    end

    describe "#followed_artists DB persistence" do
        let(:limit) { 5 }
        let(:user_id) { "user123" }

        let(:api_items) do
        (1..limit).map do |i|
            {
            "id" => "a#{i}",
            "name" => "Followed #{i}",
            "images" => [ { "url" => "img#{i}.jpg" } ],
            "genres" => [ "g#{i}" ],
            "popularity" => 50 + i,
            "external_urls" => { "spotify" => "spotify://a#{i}" }
            }
        end
        end

        before do
            session[:spotify_user] = { "id" => user_id }
            allow(client).to receive(:current_user_id).and_return(user_id)
            allow(client).to receive(:ensure_access_token!).and_return("token")
        end

        it "creates a FollowedArtistBatch + FollowedArtist records when empty" do
        stub_spotify_get("/me", body: { id: user_id })
        stub_spotify_get("/me/following", body: { artists: { items: api_items } })

        expect {
            results = client.followed_artists(limit: limit)
            expect(results.size).to eq(limit)
        }.to change(FollowedArtistBatch, :count).by(1)
        .and change(FollowedArtist, :count).by(limit)

        batch = FollowedArtistBatch.last
        expect(batch.spotify_user_id).to eq(user_id)
        expect(batch.limit).to eq(limit)
        expect(batch.followed_artists.order(:position).pluck(:spotify_id)).to eq(%w[a1 a2 a3 a4 a5])
        end

        it "reuses a fresh FollowedArtistBatch and does not hit the API" do
        batch = FollowedArtistBatch.create!(
            spotify_user_id: user_id,
            limit:           limit,
            fetched_at:      Time.current
        )
        FollowedArtist.create!(
            followed_artist_batch: batch,
            position:              1,
            spotify_id:            "cached-followed",
            name:                  "Cached Artist"
        )

        expect(client).not_to receive(:get).with("/me/following", anything, anything)

        results = client.followed_artists(limit: limit)
        expect(results.map(&:id)).to eq([ "cached-followed" ])
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
                body: { ids: [ "abc123" ] }.to_json,
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
                body: { ids: [ "123", "456" ] }.to_json,
                headers: { "Authorization" => "Bearer #{access_token}" }
                )
                .to_return(status: 204, body: "", headers: {})

            result = client.unfollow_artists([ 123, "456", 123 ])
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
            expect(result).to eq(Set.new([ "abc123" ]))
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

            result = client.followed_artist_ids([ "1", "2", "3", "1" ])
            expect(result).to eq(Set.new([ "1", "3" ]))
            end
        end

        context "when given more than 50 IDs" do
            it "splits them into batches of 50 per request" do
            ids = (1..60).to_a.map(&:to_s)
            first_batch = ids[0...50]
            second_batch = ids[50..]

            stub_request(:get, "https://api.spotify.com/v1/me/following/contains")
                .with(query: { type: "artist", ids: first_batch.join(",") })
                .to_return(status: 200, body: "[#{([ 'true' ] * 50).join(',')}]", headers: { "Content-Type" => "application/json" })

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
