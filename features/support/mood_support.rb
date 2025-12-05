Before('@mood_explorer or @mood_analysis') do
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
