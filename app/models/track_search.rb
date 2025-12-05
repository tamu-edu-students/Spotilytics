class TrackSearch < ApplicationRecord
  has_many :track_search_results, dependent: :destroy
  validates :spotify_user_id, presence: true

  scope :fresh, ->(max_age:) { where("fetched_at >= ?", max_age.ago) }
end
