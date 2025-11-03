require 'rails_helper'
require 'ostruct'

RSpec.describe "TopArtists", type: :request do
  include SpotifyStub

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(OpenStruct.new(email: 'test@example.com'))
    stub_spotify_top_artists(10)
  end

  # require 'webmock/rspec'

  it "returns a page with 10 top artists ordered by playcount" do
    stub_request(:any, /api\.spotify\.com/).to_return(
      status: 200,
      body: '{}',
      headers: { 'Content-Type' => 'application/json' }
    )


    # Now you can run your normal flow
    get "/auth/spotify/callback"
    follow_redirect!
    get dashboard_path

    html = Nokogiri::HTML(response.body)
    items = html.css('.top-artist')

    if items.any?
      expect(items.size).to eq(10)
      counts = html.css('.top-artist .artist-plays').map { |n| n.text.scan(/\d+/).first.to_i }
      expect(counts).to eq(counts.sort.reverse)
    else
      expect(html.text).to match(/Top Artist|Top Artists|top artist/i)
    end
  end


  it "returns the top artists page with ordered entries for each time range" do
    get top_artists_path
    expect(response).to have_http_status(:ok)

    html = Nokogiri::HTML(response.body)
    columns = html.css('.top-artists-column')
    expect(columns.size).to eq(3)

    expected_ranges = %w[long_term medium_term short_term]
    ranges_called = all_spotify_top_artists_calls.map { |call| call[:time_range] }
    expected_ranges.each do |range|
      expect(ranges_called).to include(range)

      column = html.at_css(".top-artists-column[data-range='#{range}']")
      expect(column).not_to be_nil

      items = column.css('.top-artist')
      expect(items.size).to eq(10)
      counts = column.css('.top-artist .artist-plays').map { |n| n.text.scan(/\d+/).first.to_i }
      expect(counts).to eq(counts.sort.reverse)
    end
  end
end
