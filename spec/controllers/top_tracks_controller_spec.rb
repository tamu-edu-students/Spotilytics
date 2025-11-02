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
        # no session[:spotify_user]
        get :index

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Please sign in with Spotify first.")
      end
    end

    context "when logged in and SpotifyClient succeeds" do
      render_views  # render the actual view so we can assert on response.body

      let(:mock_tracks) do
        [
          OpenStruct.new(
            rank: 1,
            name: "Yearly Favorite",
            artists: "Iconic Artist",
            album_name: "Best Album",
            album_image_url: "http://img/cover.jpg",
            popularity: 95,
            preview_url: nil,
            spotify_url: "https://open.spotify.com/track/abc123"
          ),
          OpenStruct.new(
            rank: 2,
            name: "Runner Up",
            artists: "Second Artist",
            album_name: "Second Album",
            album_image_url: "http://img/cover2.jpg",
            popularity: 88,
            preview_url: "http://preview.mp3",
            spotify_url: "https://open.spotify.com/track/def456"
          )
        ]
      end

      before do
        # simulate logged-in user
        session[:spotify_user] = session_user

        mock_client = instance_double(SpotifyClient)

        # controller does SpotifyClient.new(session: session)
        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        # controller calls client.top_tracks(limit: 10, time_range: "long_term")
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "long_term")
          .and_return(mock_tracks)
      end

      it "assigns @tracks and responds 200 with rendered track info" do
        get :index

        tracks_assigned = controller.instance_variable_get(:@tracks)

        expect(tracks_assigned).to eq(mock_tracks)
        expect(response).to have_http_status(:ok)

        # now that render_views is enabled, response.body should include data from index.html.erb
        expect(response.body).to include("Yearly Favorite")
        expect(response.body).to include("Iconic Artist")
      end
    end

    context "when SpotifyClient::UnauthorizedError is raised" do
      before do
        session[:spotify_user] = session_user

        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to root with session-expired alert" do
        get :index

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Session expired. Please sign in with Spotify again.")
      end
    end

    context "when SpotifyClient::Error is raised" do
      render_views  # render the view so we can assert fallback UI

      before do
        session[:spotify_user] = session_user

        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::Error.new("Spotify down"))
      end

      it "assigns [] and error message, responds 200 and shows fallback message" do
        get :index

        tracks_assigned = controller.instance_variable_get(:@tracks)
        error_assigned  = controller.instance_variable_get(:@error)

        expect(tracks_assigned).to eq([])
        expect(error_assigned).to eq("Couldn't load your top tracks from Spotify.")

        expect(response).to have_http_status(:ok)

        # HTML escapes "Couldn't" as Couldn&#39;t, so assert on that
        expect(response.body).to include("Couldn&#39;t load your top tracks from Spotify.")
        expect(response.body).to include("We don't have your top tracks yet").or include("We don&#39;t have your top tracks yet")
      end
    end

    context "when logged in with a custom limit" do
      render_views

      let(:mock_tracks) { [] }
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return(mock_tracks)
      end

      it "calls Spotify with limit=25" do
        get :index, params: { limit: "25" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 25, time_range: "long_term")
        expect(response).to have_http_status(:ok)
      end

      it "calls Spotify with limit=50" do
        get :index, params: { limit: "50" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 50, time_range: "long_term")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when logged in with an invalid limit" do
      let(:mock_tracks) { [] }
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return(mock_tracks)
      end

      it "falls back to limit=10" do
        get :index, params: { limit: "999" }

        expect(mock_client).to have_received(:top_tracks)
          .with(limit: 10, time_range: "long_term")
        expect(response).to have_http_status(:ok)
      end
    end

    context "limit selector rendering" do
      render_views

      let(:mock_tracks) { [] }
      let(:mock_client) { instance_double(SpotifyClient) }

      before do
        session[:spotify_user] = session_user
        allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
        allow(mock_client).to receive(:top_tracks).and_return(mock_tracks)
      end

      it "marks Top 25 as selected when limit=25 is passed" do
        get :index, params: { limit: "25" }
        expect(response.body).to include('<option selected="selected" value="25">')
      end
    end
  end
end
