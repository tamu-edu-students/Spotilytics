Given("I am an authenticated user with spotify data") do
  # Create or find a test user and stub Spotify API responses
  @user = User.find_by(email: 'test@example.com') || FactoryBot.create(:user, email: 'test@example.com')
  # sign in (Devise helper available in features if configured)
  if respond_to?(:sign_in)
    sign_in(@user)
  else
    visit new_user_session_path
    fill_in 'Email', with: @user.email
    fill_in 'Password', with: @user.password || 'password'
    click_button 'Log in'
  end

  # Stub Spotify API top artists
  stub_spotify_top_artists(10)
end

When("I visit the top artists page") do
  visit top_artists_path
end

Then("I should see a list of 10 artists") do
  expect(page).to have_css('.top-artist', count: 10)
end

Then("the artists should be ordered by play count descending") do
  names = page.all('.top-artist .artist-name').map(&:text)
  # we stubbed them with counts so verify ordering by the suffix ' (plays: N)'
  counts = page.all('.top-artist .artist-plays').map { |el| el.text.scan(/\d+/).first.to_i }
  expect(counts).to eq(counts.sort.reverse)
end

