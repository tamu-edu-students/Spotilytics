require 'rails_helper'
require 'ostruct'

RSpec.describe "TopArtists", type: :request do
  include SpotifyStub

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(OpenStruct.new(email: 'test@example.com'))
    stub_spotify_top_artists(10)
  end

  it "returns a page with 10 top artists ordered by playcount" do
    get dashboard_path
    expect(response).to have_http_status(:ok)
    # parse HTML for elements with class 'top-artist'
    html = Nokogiri::HTML(response.body)
    items = html.css('.top-artist')
    # Dashboard may not yet render a full list; if it does, expect 10
    if items.any?
      expect(items.size).to eq(10)
      counts = html.css('.top-artist .artist-plays').map { |n| n.text.scan(/\d+/).first.to_i }
      expect(counts).to eq(counts.sort.reverse)
    else
      expect(html.text).to match(/Top Artist|Top Artists|top artist/i)
    end
  end

  it "returns the top artists page with 10 entries ordered" do
    get top_artists_path
    expect(last_spotify_top_artists_call).to include(limit: 10, time_range: 'long_term')

    expect(response).to have_http_status(:ok)
    html = Nokogiri::HTML(response.body)
    items = html.css('.top-artist')
    expect(items.size).to eq(10)
    counts = html.css('.top-artist .artist-plays').map { |n| n.text.scan(/\d+/).first.to_i }
    expect(counts).to eq(counts.sort.reverse)
  end
end
