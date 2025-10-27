require "rails_helper"

RSpec.describe "Pages Controller", type: :request do
    describe "Home Page" do
        it "successfully loads" do
            get "/home"
            expect(response).to have_http_status(:ok)
        end
        it "displays the names of all page contributors" do
            get "/home"
            expect(response.body).to include("Aurora Jitrskul", "Pablo Pineda", "Spoorthy Raghavendra", "Aditya Vellampalli")
        end
        it "correctly provides a link to login when user is not logged in" do
            get "/home"
            html = Nokogiri::HTML(response.body)
            link = html.at_css('a.home-page-button')

            expect(link['href']).to eq('/auth/spotify')
        end
        it "correctly provides a link to dashboard when user is logged in" do
            get "/auth/spotify/callback"
            get "/home"
            html = Nokogiri::HTML(response.body)
            link = html.at_css('a.home-page-button')

            expect(link['href']).to eq('/dashboard')
        end
    end
    describe "Dashboard" do
        it "correctly redirects when the user is not logged in" do
            get dashboard_path
            expect(response).to redirect_to(home_path)
        end
        it "correctly has a popup on home page when the user is not logged in" do
            get dashboard_path  
            follow_redirect!
            expect(response.body).to include("You must log in with spotify to access the dashboard.")
        end
    end
end