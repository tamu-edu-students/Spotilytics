require 'rails_helper'

RSpec.describe "TopArtists", type: :request do
  include SpotifyStub

  let!(:user) { FactoryBot.create(:user) }

  before do
    sign_in user if respond_to?(:sign_in)
    stub_spotify_top_artists(10)
  end

  it "returns a page with 10 top artists ordered by playcount" do
    get top_artists_path
    expect(response).to have_http_status(:ok)
    # parse HTML for elements with class 'top-artist'
    html = Nokogiri::HTML(response.body)
    items = html.css('.top-artist')
    expect(items.size).to eq(10)

    counts = html.css('.top-artist .artist-plays').map { |n| n.text.scan(/\d+/).first.to_i }
    expect(counts).to eq(counts.sort.reverse)
  end
end
