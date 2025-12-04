Given("I am logged in with a stubbed Spotify user") do
  if page.respond_to?(:set_rack_session)
    page.set_rack_session(
      spotify_user: {
        "id"           => "test-user",
        "display_name" => "Test User",
        "email"        => "test@example.com"
      }
    )
  end
end

When("I open the Mood Explorer tab") do
  visit "/mood-explorer"
  click_link "Mood Explorer"
end

Then("I should see a mood group header for {string}") do |mood_name|
  expect(page).to have_css(".mood-group-title", text: mood_name)
end

Then("I should see at least one track card") do
  expect(page).to have_css(".mood-track-card", minimum: 1)
end

When("I follow {string} for the first track") do |link_text|
  within first(".mood-track-card") do
    click_link link_text
  end
end

Then("I should be on the mood analysis page") do
  expect(current_path).to match(%r{\A/mood-analysis/})
end
