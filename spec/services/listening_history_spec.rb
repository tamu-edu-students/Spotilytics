require "rails_helper"

RSpec.describe ListeningHistory do
  let(:spotify_user_id) { "user-123" }
  let(:history) { described_class.new(spotify_user_id: spotify_user_id) }

  describe "#ingest! and #recent_entries" do
    it "stores plays and returns them in descending order" do
      plays = [
        OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: Time.utc(2025, 1, 2, 10, 0, 0)),
        OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: Time.utc(2025, 1, 1, 10, 0, 0))
      ]

      history.ingest!(plays)
      entries = history.recent_entries(limit: 10)

      expect(entries.map(&:id)).to eq(%w[t1 t2])
      expect(ListeningPlay.count).to eq(2)
    end

    it "deduplicates by user + track + played_at" do
      time = Time.utc(2025, 1, 1, 12, 0, 0)
      dup_play = OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: time)

      history.ingest!([ dup_play, dup_play ])

      expect(ListeningPlay.count).to eq(1)
      expect(history.recent_entries(limit: 5).size).to eq(1)
    end
  end
end
