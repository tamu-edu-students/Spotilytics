# spec/controllers/pages_controller_dashboard_top_tracks_spec.rb
require "rails_helper"

RSpec.describe PagesController, type: :controller do
  describe "GET #dashboard (Top Tracks preview section)" do
    let(:session_user) do
      {
        "display_name" => "Test Listener",
        "email"        => "listener@example.com",
        "image"        => "http://example.com/user.jpg"
      }
    end

    before do
      # simulate a logged-in Spotify user so the controller doesn't bounce us
      session[:spotify_user] = session_user
    end

    context "when SpotifyClient returns top tracks successfully" do
      render_views

      let(:mock_tracks) do
        [
          OpenStruct.new(
            name: "Track One",
            artists: "Artist One",
            album_name: "Album One",
            album_image_url: "http://img/one.jpg",
            popularity: 90
          ),
          OpenStruct.new(
            name: "Track Two",
            artists: "Artist Two",
            album_name: "Album Two",
            album_image_url: "http://img/two.jpg",
            popularity: 80
          )
        ]
      end

      before do
        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        # dashboard builds top tracks preview with 10/long_term
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "long_term")
          .and_return(mock_tracks)

        # dashboard also fetches top artists; stub it to something harmless
        allow(mock_client).to receive(:top_artists).and_return([])
      end

      it "assigns top tracks and primary track for the preview card" do
        get :dashboard

        expect(assigns(:top_tracks)).to eq(mock_tracks)
        expect(assigns(:primary_track)).to eq(mock_tracks.first)
        expect(response).to have_http_status(:ok)

        # light smoke check against the rendered HTML
        expect(response.body).to include("Track One")
        expect(response.body).to include("Artist One")
      end
    end

    context "when SpotifyClient raises UnauthorizedError while fetching top tracks" do
      before do
        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))

        # stub other calls invoked by dashboard to also fail the same way
        allow(mock_client).to receive(:top_artists)
          .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))
      end

      it "redirects to home with the re-auth alert" do
        get :dashboard

        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq(
          "You must log in with spotify to access the dashboard."
        )
      end
    end

    context "when SpotifyClient raises a generic Error while fetching top tracks" do
      render_views

      before do
        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::Error.new("rate limited"))

        allow(mock_client).to receive(:top_artists)
          .and_raise(SpotifyClient::Error.new("rate limited"))
      end

      it "renders 200, sets flash.now alert, and assigns empty preview values" do
        get :dashboard

        expect(assigns(:top_tracks)).to eq([])
        expect(assigns(:primary_track)).to be_nil

        expect(flash.now[:alert]).to eq(
          "We were unable to load your Spotify data right now. Please try again later."
        )
        expect(response).to have_http_status(:ok)

        # optional: smoke check that dashboard content rendered
        expect(response.body).to include("Top Tracks").or include("Your Top")
      end
    end
  end
end