require "rails_helper"

RSpec.describe "Mood Analysis", type: :request do
  let(:spotify_user) { { "id" => "user123" } }

  let(:tracks) do
    [
      OpenStruct.new(
        id: "track1",
        name: "Song One",
        artists: "Artist A",
        image: "http://img/1"
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
      .and_return(tracks)

    allow(ReccoBeatsClient)
      .to receive(:fetch_audio_features)
      .with([ "track1" ])
      .and_return(features)
  end

  describe "GET /mood-analysis/:id" do
    it "renders the analysis page when track exists" do
      get mood_analysis_path("track1")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Song One")
      expect(response.body).to include("Feature Breakdown")
    end

    it "redirects back if track is not in top tracks" do
      get mood_analysis_path("missing-track")

      expect(response).to redirect_to(mood_explorer_path)
      expect(flash[:alert]).to eq("Track not found in your top 10 tracks.")
    end
  end
end
