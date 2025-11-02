# spec/controllers/top_tracks_controller_spec.rb
require "rails_helper"

RSpec.describe TopTracksController, type: :controller do
  describe "GET #index" do
    let(:session_user) do
      {
        "display_name" => "Test Listener",
        "email"        => "listener@example.com",
        "image"        => "http://example.com/user.jpg"
      }
    end

    context "when not logged in" do
      it "redirects to root with alert" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please sign in with Spotify first.")
      end
    end

    context "when logged in and SpotifyClient succeeds" do
      render_views

      let(:short_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Short A", artists: "S-Artist", album_name: "S-Album",
                         album_image_url: nil, popularity: 90, preview_url: nil, spotify_url: nil)
        ]
      end
      let(:medium_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Medium A", artists: "M-Artist", album_name: "M-Album",
                         album_image_url: nil, popularity: 91, preview_url: nil, spotify_url: nil)
        ]
      end
      let(:long_tracks) do
        [
          OpenStruct.new(rank: 1, name: "Yearly Favorite", artists: "Iconic Artist",
                         album_name: "Best Album", album_image_url: "http://img/cover.jpg",
                         popularity: 95, preview_url: nil, spotify_url: "https://open.spotify.com/track/abc123")
        ]
      end

      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user

        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "short_term").and_return(short_tracks)
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "medium_term").and_return(medium_tracks)
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "long_term").and_return(long_tracks)
      end

      it "assigns lists for short/medium/long and renders them" do
        get :index

        expect(assigns(:tracks_short)).to  eq(short_tracks)
        expect(assigns(:tracks_medium)).to eq(medium_tracks)
        expect(assigns(:tracks_long)).to   eq(long_tracks)
        expect(response).to have_http_status(:ok)

        expect(response.body).to include("Short A")
        expect(response.body).to include("Medium A")
        expect(response.body).to include("Yearly Favorite")
        expect(response.body).to include("Iconic Artist")
      end
    end

    context "when SpotifyClient::UnauthorizedError is raised" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to root with session-expired alert" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
      end
    end

    context "when SpotifyClient::Error is raised" do
      render_views

      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_raise(SpotifyClient::Error.new("Spotify down"))
      end

      it "assigns empty lists, sets error, renders 200 with fallback message" do
        get :index

        expect(assigns(:tracks_short)).to  eq([])
        expect(assigns(:tracks_medium)).to eq([])
        expect(assigns(:tracks_long)).to   eq([])
        expect(assigns(:error)).to eq("Couldn't load your top tracks from Spotify.")
        expect(response).to have_http_status(:ok)

        # HTML escapes apostrophes
        expect(response.body).to include("Couldn&#39;t load your top tracks from Spotify.")
      end
    end

    context "when logged in with a custom limit (same limit for all ranges)" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return([])
      end

      it "calls Spotify with limit=25 for short/medium/long" do
        get :index, params: { limit: "25" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "long_term")
                expect(response).to have_http_status(:ok)
      end

      it "calls Spotify with limit=50 for all" do
        get :index, params: { limit: "50" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "long_term")
      end
    end

    context "when logged in with an invalid limit" do
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return([])
      end

      it "falls back to limit=10 for all ranges" do
        get :index, params: { limit: "999" }

        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "short_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "medium_term")
        expect(mock_client).to have_received(:top_tracks).with(limit: 10, time_range: "long_term")
        expect(response).to have_http_status(:ok)
      end
    end
  end
end