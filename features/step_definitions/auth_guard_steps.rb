unless defined?(CucumberAuthProbeController)
  class CucumberAuthProbeController < ApplicationController
    before_action :require_spotify_auth!
    def index
      render plain: "Protected OK"
    end
  end
end

unless defined?(CucumberSessionController)
  class CucumberSessionController < ApplicationController
    def login
      session[:spotify_user] = { "id" => "cuke_user", "display_name" => "Cuke User" }
      render plain: "logged-in"
    end

    def logout
      session.delete(:spotify_user)
      render plain: "logged-out"
    end
  end
end

Given("a protected test page that requires Spotify login") do
  Rails.application.routes.draw do
    get "/auth_probe",  to: "cucumber_auth_probe#index"
    get "/cuke_login",  to: "cucumber_session#login"
    get "/cuke_logout", to: "cucumber_session#logout"

    get "/home", to: "pages#home", as: :home
    root "pages#home"
  end
end

After do
  Rails.application.reload_routes!
end

Given("I am not logged in") { visit "/cuke_logout" }
Given("I am logged in")     { visit "/cuke_login"   }

When("I visit the protected test page") { visit "/auth_probe" }

Then("I should be redirected to the home page") do
  expect(page).to have_current_path("/home")
end

Then("I should see the login required alert") do
  expect(page).to have_content("You must log in with spotify to view this page.")
end

Then("I should not see the login required alert") do
  expect(page).not_to have_content("You must log in with spotify to view this page.")
end
