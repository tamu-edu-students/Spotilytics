require "rails_helper"

RSpec.describe PersonalityController, type: :controller do
  let(:session_user) do
    {
      "id"           => "spotify-user-1",
      "display_name" => "Test Listener",
      "email"        => "listener@example.com"
    }
  end

  before { session[:spotify_user] = session_user }

  describe "GET #show" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:mock_history) { instance_double(ListeningHistory) }
    let(:features) do
      {
        "t1" => OpenStruct.new(id: "t1", energy: 0.8, valence: 0.6, danceability: 0.7, tempo: 130, acousticness: 0.1, instrumentalness: 0.1)
      }
    end
    let(:plays) { [ OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 1, 10)) ] }
    let(:top_tracks) { [ OpenStruct.new(id: "t1", name: "One", artists: "A") ] }

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
      allow(ListeningHistory).to receive(:new).with(spotify_user_id: "spotify-user-1").and_return(mock_history)
    end

    it "assigns summary and stats" do
      allow(mock_client).to receive(:recently_played).and_return([])
      allow(mock_history).to receive(:ingest!).with([])
      allow(mock_client).to receive(:top_tracks).and_return(top_tracks)
      allow(mock_client).to receive(:track_audio_features).and_return(features)
      allow(mock_history).to receive(:recent_entries).with(limit: 300).and_return(plays)

      get :show

      expect(response).to have_http_status(:ok)
      expect(assigns(:summary)).to be_present
      expect(assigns(:stats)).to be_present
      expect(assigns(:sample_size)).to eq(1)
    end
  end
end
