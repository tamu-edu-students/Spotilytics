class TopTrackBatch < ApplicationRecord
  has_many :top_track_results, dependent: :destroy

  validates :spotify_user_id, :time_range, :limit, :fetched_at, presence: true
end