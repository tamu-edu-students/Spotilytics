require "rails_helper"

RSpec.describe MonthlyListeningStats do
  let(:client) { instance_double(SpotifyClient) }
  let(:service) { described_class.new(client: client, time_zone: ActiveSupport::TimeZone["UTC"]) }

  describe "#summary" do
    let(:plays) do
      [
        OpenStruct.new(played_at: Time.utc(2025, 1, 5, 10, 0, 0), duration_ms: 120_000),
        OpenStruct.new(played_at: Time.utc(2025, 1, 20, 12, 0, 0), duration_ms: 180_000),
        OpenStruct.new(played_at: Time.utc(2025, 2, 2, 14, 30, 0), duration_ms: 3_600_000)
      ]
    end

    before do
      allow(client).to receive(:recently_played).with(limit: 600).and_return(plays)
    end

    it "sums durations per month and tracks sample size" do
      summary = service.summary(limit: 600)

      expect(summary[:buckets].length).to eq(2)
      expect(summary[:buckets].first[:label]).to eq("Jan 2025")
      expect(summary[:buckets].first[:hours]).to eq(0.08)
      expect(summary[:buckets].last[:hours]).to eq(1.0)
      expect(summary[:sample_size]).to eq(3)
      expect(summary[:total_duration_ms]).to eq(3_900_000)
      expect(summary[:history_window]).to eq([plays.first.played_at, plays.last.played_at])
    end
  end

  describe "#chart_data" do
    before do
      allow(client).to receive(:recently_played).and_return([])
    end

    it "returns chart-friendly structure even when empty" do
      data = service.chart_data(limit: 100)

      expect(data[:chart]).to be_present
      expect(data[:chart][:labels]).to eq([])
      expect(data[:chart][:datasets]).to eq([])
      expect(data[:sample_size]).to eq(0)
    end
  end
end
