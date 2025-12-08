RSpec.describe "Home Page Request", type: :request do
    describe "Home Page" do
        it "successfully loads" do
            get "/home"
            expect(response).to have_http_status(:ok)
        end
        it "displays the names of all page contributors" do
            get "/home"
            expect(response.body).to include("Charlie Chiu", "Cameron Yoffe", "Spoorthy Raghavendra", "Venkateswarlu Nagineni")
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
end
