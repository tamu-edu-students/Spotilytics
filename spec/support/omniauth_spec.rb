require "omniauth"

RSpec.configure do |config|
  config.before(:suite) do
    OmniAuth.config.test_mode = true
  end

  config.before do
    # default to a valid Spotify auth hash
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

  config.after(:suite) do
    OmniAuth.config.test_mode = false
  end
end
