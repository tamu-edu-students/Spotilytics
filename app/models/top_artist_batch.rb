class TopArtistBatch < ApplicationRecord
  has_many :top_artist_results, dependent: :destroy

  validates :spotify_user_id, :time_range, :limit, :fetched_at, presence: true
end