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
      render_views  # we assert on rendered HTML that shows the preview

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

        # dashboard uses SpotifyClient.new(session: session)
        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        # dashboard uses top_tracks(limit: 10, time_range: "long_term")
        # to build @top_tracks and @primary_track for the preview card
        allow(mock_client).to receive(:top_tracks)
          .with(limit: 10, time_range: "long_term")
          .and_return(mock_tracks)

        # Stub any other Spotify calls that the controller might make so they
        # don't explode, but we won't assert on them.
        allow(mock_client).to receive(:top_artists).and_return([])
      end

      it "assigns @top_tracks and @primary_track for the Top Tracks preview card" do
        get :dashboard

        top_tracks_assigned    = controller.instance_variable_get(:@top_tracks)
        primary_track_assigned = controller.instance_variable_get(:@primary_track)

        expect(top_tracks_assigned).to eq(mock_tracks)
        expect(primary_track_assigned).to eq(mock_tracks.first)

        # dashboard should render successfully (not redirect)
        expect(response).to have_http_status(:ok)

        # Sanity check that the preview card content is visible in HTML.
        # We only assert Top Tracks content (not other dashboard widgets).
        expect(response.body).to include("Track One")
        expect(response.body).to include("Artist One")
      end
    end

    context "when SpotifyClient raises UnauthorizedError while fetching top tracks" do
      # This path is important: user can’t see the Top Tracks preview until they re-auth.

      before do
        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        # The preview cannot be built because top_tracks fails with expired auth.
        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))

        # Stub unrelated dashboard data so it doesn't affect control flow here.
        allow(mock_client).to receive(:top_artists)
          .and_raise(SpotifyClient::UnauthorizedError.new("expired token"))
      end

      it "redirects user to login_path and shows the re-auth alert" do
        get :dashboard

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(
          "Please sign in with Spotify to view your dashboard."
        )
      end
    end

    context "when SpotifyClient raises a generic Error while fetching top tracks" do
      render_views  # we assert that dashboard still renders a fallback card

      before do
        mock_client = instance_double(SpotifyClient)

        allow(SpotifyClient).to receive(:new)
          .with(session: anything)
          .and_return(mock_client)

        # Simulate Spotify API hiccup. Dashboard should still render,
        # but the Top Tracks preview should be empty/safe.
        allow(mock_client).to receive(:top_tracks)
          .and_raise(SpotifyClient::Error.new("rate limited"))

        # Stub any other calls so they don't derail rendering.
        allow(mock_client).to receive(:top_artists)
          .and_raise(SpotifyClient::Error.new("rate limited"))
      end

      it "falls back to an empty Top Tracks preview, sets flash.now alert, and still renders dashboard" do
        get :dashboard

        top_tracks_assigned    = controller.instance_variable_get(:@top_tracks)
        primary_track_assigned = controller.instance_variable_get(:@primary_track)

        # Controller should give the view something stable for the Top Tracks card.
        expect(top_tracks_assigned).to eq([])
        expect(primary_track_assigned).to eq(nil)

        # The controller should set a warning message for the user.
        expect(flash.now[:alert]).to eq(
          "We were unable to load your Spotify data right now. Please try again later."
        )

        # We stay on dashboard (200), not kicked out.
        expect(response).        to have_http_status(:ok)

        # Gentle smoke check: dashboard HTML still contains the Top Tracks section.
        expect(response.body).to include("Top Tracks")
      end
    end
  end
end
