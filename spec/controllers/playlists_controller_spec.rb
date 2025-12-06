require "rails_helper"

RSpec.describe PlaylistsController, type: :controller do
  let(:session_user) do
    { "id" => "spotify-user-1", "display_name" => "Test User" }
  end

  before { session[:spotify_user] = session_user }

  describe "GET #compare" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:mock_service) { instance_double(PlaylistComparisonService) }
    let(:mock_result) do
      PlaylistComparisonService::CompatibilityResult.new(
        compatibility: 90,
        overlap_count: 2,
        overlap_pct: 50.0,
        common_tracks: [],
        only_in_a: [],
        only_in_b: [],
        vector_a: [ 1, 0, 0, 0, 0 ],
        vector_b: [ 1, 0, 0, 0, 0 ],
        valid_a: 5,
        valid_b: 5,
        flags: []
      )
    end

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
      allow(PlaylistComparisonService).to receive(:new).with(client: mock_client).and_return(mock_service)
      allow(mock_service).to receive(:compare).and_return(mock_result)
    end

    it "assigns comparison data" do
      get :compare, params: { source_id: "plA", target_id: "plB" }

      expect(response).to have_http_status(:ok)
      expect(assigns(:compatibility_score)).to eq(90)
      expect(assigns(:overlap_count)).to eq(2)
      expect(assigns(:overlap_pct)).to eq(50.0)
      expect(assigns(:vector_a)).to eq([1, 0, 0, 0, 0])
      expect(assigns(:explanations)).to be_present
    end

    it "redirects when ids missing" do
      get :compare, params: { source_id: "", target_id: "" }

      expect(response).to redirect_to(compare_form_playlists_path)
      expect(flash[:alert]).to eq("Please enter both playlist IDs.")
    end
  end

  describe "#normalize_playlist_id" do
    controller(PlaylistsController) do
      def fake; render plain: normalize_playlist_id(params[:id]); end
    end

    it "extracts id from spotify url" do
      allow(controller).to receive(:require_spotify_auth!).and_return(true)
      get :fake, params: { id: "https://open.spotify.com/playlist/abc123?si=xyz" }
      expect(response.body).to eq("abc123")
    end

    it "returns stripped id when raw" do
      allow(controller).to receive(:require_spotify_auth!).and_return(true)
      get :fake, params: { id: "  raw123  " }
      expect(response.body).to eq("raw123")
    end
  end
end
