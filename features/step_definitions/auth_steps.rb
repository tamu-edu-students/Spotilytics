Given("OmniAuth is in test mode") do
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

Given("I am signed in with Spotify") do
  step %(OmniAuth is in test mode)
  visit "/auth/spotify"
  visit "/auth/spotify/callback"
end

Given("I am on the home page") do
  visit root_path
end

Given("OmniAuth will return {string}") do |kind|
  case kind
  when "developer access not configured"
    OmniAuth.config.mock_auth[:spotify] = :developer_access_not_configured
  else
    raise "Unknown mock kind: #{kind}"
  end
end

When("I click {string}") do |text|
  click_link_or_button text
end

When('I visit {string}') do |path|
  visit path
end

Then("I should be on the home page") do
  uri  = Addressable::URI.parse(page.current_url)
  path = uri.path
  home = Rails.application.routes.url_helpers.home_path
  root = Rails.application.routes.url_helpers.root_path
  expect([ home, root ]).to include(path)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end
