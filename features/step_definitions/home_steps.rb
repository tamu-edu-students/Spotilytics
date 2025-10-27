Then("I should be on the dashboard page") do
  expect(page).to have_current_path(dashboard_path, ignore_query: true)
end