require "rails_helper"

RSpec.describe MusicPersonality do
  let(:features) do
    [
      OpenStruct.new(energy: 0.8, valence: 0.7, danceability: 0.75, tempo: 135, acousticness: 0.1, instrumentalness: 0.2),
      OpenStruct.new(energy: 0.75, valence: 0.6, danceability: 0.7, tempo: 132, acousticness: 0.15, instrumentalness: 0.1)
    ]
  end

  let(:hour_counts) { { 0 => 2, 22 => 3 } }

  subject { described_class.new(features: features, hour_counts: hour_counts) }

  it "produces a high-energy night owl summary" do
    summary = subject.summary
    expect(summary.title).to include("High-Energy")
    expect(summary.hour_focus).to eq("Evening")
    expect(summary.traits).to include("Dancefloor-ready")
  end

  it "returns averaged stats" do
    stats = subject.stats
    expect(stats[:energy]).to be > 0.75
    expect(stats[:tempo]).to be_between(130, 140)
  end
end
