require "rails_helper"

RSpec.describe "Listening Heatmap page", type: :feature do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:spotify] = OmniAuth::AuthHash.new(
      provider: "spotify",
      uid: "spotify-uid-123",
      info: {
        name:  "Test User",
        email: "test-user@example.com",
        image: "https://pics.example/avatar.png"
      },
      credentials: {
        token:         "access-token-1",
        refresh_token: "refresh-token-1",
        expires_at:    2.hours.from_now.to_i
      }
    )
  end

  let(:plays) do
    [
      OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 1, 10, 0, 0)),
      OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: Time.utc(2025, 1, 2, 12, 0, 0))
    ]
  end

  it "renders the calendar heatmap with sample size" do
    allow_any_instance_of(SpotifyClient).to receive(:recently_played).and_return(plays)

    visit "/auth/spotify"
    visit "/auth/spotify/callback"
    visit listening_heatmap_path

    expect(page).to have_content("Calendar heatmap")
    expect(page).to have_content("Plays captured")
    expect(page).to have_content("2")
  end
end
