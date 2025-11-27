require "rails_helper"

RSpec.describe ListeningPatternsController, type: :controller do
  let(:session_user) do
    {
      "display_name" => "Test Listener",
      "email"        => "listener@example.com",
      "image"        => "http://example.com/user.jpg"
    }
  end

  before { session[:spotify_user] = session_user }

  describe "GET #hourly" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:plays) do
      [
        OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 1, 10, 0, 0)),
        OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: Time.utc(2025, 1, 1, 11, 0, 0))
      ]
    end

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
    end

    context "when Spotify data loads successfully" do
      before do
        allow(mock_client).to receive(:recently_played).with(limit: 25).and_return(plays)
      end

      it "assigns chart data and responds with success" do
        get :hourly, params: { limit: 25 }

        expect(response).to have_http_status(:ok)
        expect(assigns(:sample_size)).to eq(2)
        expect(assigns(:total_plays)).to eq(2)
        expect(assigns(:hourly_chart)).to be_present
        expect(assigns(:top_hours)).to be_present
      end
    end

    context "when Spotify requires re-authentication" do
      before do
        allow(mock_client).to receive(:recently_played).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to home with alert" do
        get :hourly

        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq("You must log in with spotify to view your listening patterns.")
      end
    end

    context "when Spotify returns insufficient scope" do
      before do
        session[:spotify_token] = "t"
        session[:spotify_refresh_token] = "r"
        session[:spotify_expires_at] = 123

        allow(mock_client).to receive(:recently_played).and_raise(
          SpotifyClient::Error.new("Insufficient client scope")
        )
      end

      it "resets session tokens and redirects to login" do
        get :hourly

        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq("Spotify now needs permission to read your Recently Played history. Please sign in again.")
        expect(session[:spotify_token]).to be_nil
        expect(session[:spotify_refresh_token]).to be_nil
        expect(session[:spotify_expires_at]).to be_nil
      end
    end

    context "when user is not logged in" do
      before { session.delete(:spotify_user) }

      it "redirects to home" do
        get :hourly
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq("You must log in with spotify to view this page.")
      end
    end
  end
end
