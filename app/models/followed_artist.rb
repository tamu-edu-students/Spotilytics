class FollowedArtist < ApplicationRecord
  belongs_to :followed_artist_batch

  serialize :genres, coder: JSON
end