require 'rails_helper'

RSpec.describe "TopTracks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/top_tracks/index"
      expect(response).to have_http_status(:success)
    end
  end

end
