require "rails_helper"

RSpec.describe ListeningPatternsController, type: :controller do
  let(:session_user) do
    {
      "id"           => "spotify-user-1",
      "display_name" => "Test Listener",
      "email"        => "listener@example.com",
      "image"        => "http://example.com/user.jpg"
    }
  end

  before { session[:spotify_user] = session_user }

  describe "GET #hourly" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:mock_history) { instance_double(ListeningHistory) }
    let(:plays) do
      [
        OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 1, 10, 0, 0)),
        OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: Time.utc(2025, 1, 1, 11, 0, 0))
      ]
    end

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
      allow(ListeningHistory).to receive(:new).with(spotify_user_id: "spotify-user-1").and_return(mock_history)
    end

    context "when Spotify data loads successfully" do
      before do
        allow(mock_client).to receive(:recently_played).and_return(plays)
        allow(mock_history).to receive(:ingest!).with(plays)
        allow(mock_history).to receive(:recent_entries).with(limit: 50).and_return(plays)
      end

      it "assigns chart data and responds with success" do
        get :hourly, params: { limit: 50 }

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

  describe "GET #calendar" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:mock_history) { instance_double(ListeningHistory) }
    let(:plays) do
      [
        OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 1, 10, 0, 0)),
        OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: Time.utc(2025, 1, 2, 12, 0, 0))
      ]
    end

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
      allow(ListeningHistory).to receive(:new).with(spotify_user_id: "spotify-user-1").and_return(mock_history)
    end

    context "when Spotify data loads successfully" do
      before do
        allow(mock_client).to receive(:recently_played).and_return(plays)
        allow(mock_history).to receive(:ingest!).with(plays)
        allow(mock_history).to receive(:recent_entries).with(limit: 500).and_return(plays)
      end

      it "assigns weeks data and sample size" do
        get :calendar

        expect(response).to have_http_status(:ok)
        expect(assigns(:weeks)).to be_present
        expect(assigns(:sample_size)).to eq(2)
      end
    end

    context "when Spotify requires re-authentication" do
      before do
        allow(mock_client).to receive(:recently_played).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to home with alert" do
        get :calendar
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq("You must log in with spotify to view your listening patterns.")
      end
    end
  end

  describe "GET #monthly" do
    let(:mock_client) { instance_double(SpotifyClient) }
    let(:stats_service) { instance_double(MonthlyListeningStats) }
    let(:chart_summary) do
      start_time = Time.utc(2025, 1, 1, 12, 0, 0)
      end_time = Time.utc(2025, 3, 5, 18, 0, 0)

      {
        chart: { labels: [ "Dec 2024", "Jan 2025" ], datasets: [ { data: [ 2.0, 1.5 ] } ] },
        buckets: [
          { label: "Dec 2024", hours: 2.0, play_count: 40, month: start_time.beginning_of_month - 1.month, duration_ms: 7_200_000 },
          { label: "Jan 2025", hours: 1.5, play_count: 30, month: start_time.beginning_of_month, duration_ms: 5_400_000 }
        ],
        sample_size: 70,
        total_duration_ms: 12_600_000,
        history_window: [ start_time, end_time ]
      }
    end

    before do
      allow(SpotifyClient).to receive(:new).with(session: anything).and_return(mock_client)
      allow(MonthlyListeningStats).to receive(:new).with(client: mock_client, time_zone: Time.zone).and_return(stats_service)
    end

    context "when Spotify data loads successfully" do
      before do
        allow(stats_service).to receive(:chart_data).with(limit: 500).and_return(chart_summary)
      end

      it "assigns chart data and responds with success" do
        get :monthly

        expect(response).to have_http_status(:ok)
        expect(assigns(:chart_data)).to eq(chart_summary[:chart])
        expect(assigns(:buckets)).to eq(chart_summary[:buckets])
        expect(assigns(:sample_size)).to eq(70)
        expect(assigns(:total_hours)).to eq(3.5)
        expect(assigns(:previous_month)).to eq(chart_summary[:buckets].first)
      end
    end

    context "when Spotify requires re-authentication" do
      before do
        allow(stats_service).to receive(:chart_data).and_raise(SpotifyClient::UnauthorizedError.new("expired"))
      end

      it "redirects to home with alert" do
        get :monthly

        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to eq("You must log in with spotify to view your listening patterns.")
      end
    end
  end
end
