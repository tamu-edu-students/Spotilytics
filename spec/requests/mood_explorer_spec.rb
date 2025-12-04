require "rails_helper"

RSpec.describe "Mood Explorer", type: :request do
  let(:spotify_user) do
    {
      "id" => "user123",
      "display_name" => "Test User",
      "email" => "user@example.com"
    }
  end

  describe "GET /mood-explorer" do
    context "when not logged in" do
      it "redirects to home with alert" do
        get mood_explorer_path

        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq("Log in with Spotify first.")
      end
    end

    context "when logged in" do
      let(:tracks) do
        [
          OpenStruct.new(
            id: "track1",
            name: "Song One",
            artists: "Artist A",
            image: "http://img/1"
          ),
          OpenStruct.new(
            id: "track2",
            name: "Song Two",
            artists: "Artist B",
            image: "http://img/2"
          )
        ]
      end

      let(:features) do
        [
          {
            "spotify_id"    => "track1",
            "energy"        => 0.9,
            "valence"       => 0.8,
            "danceability"  => 0.75,
            "acousticness"  => 0.1,
            "tempo"         => 120
          },
          {
            "spotify_id"    => "track2",
            "energy"        => 0.3,
            "valence"       => 0.3,
            "danceability"  => 0.4,
            "acousticness"  => 0.2,
            "tempo"         => 90
          }
        ]
      end

      before do
        allow_any_instance_of(ActionDispatch::Request)
          .to receive(:session)
          .and_wrap_original do |m, *args|
            sess = m.call(*args)
            sess[:spotify_user] ||= spotify_user
            sess
          end

        allow_any_instance_of(SpotifyClient)
          .to receive(:top_tracks_1)
          .with(limit: 10)
          .and_return(tracks)

        allow(ReccoBeatsClient)
          .to receive(:fetch_audio_features)
          .with(%w[track1 track2])
          .and_return(features)
      end

      it "renders successfully" do
        get mood_explorer_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Songs Mood Explorer")
        expect(response.body).to include("Song One")
      end
    end
  end
end
