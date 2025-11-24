class FollowedArtistBatch < ApplicationRecord
  has_many :followed_artists, dependent: :destroy
  validates :spotify_user_id, presence: true
end
