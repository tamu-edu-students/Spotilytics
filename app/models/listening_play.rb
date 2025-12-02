class ListeningPlay < ApplicationRecord
  validates :spotify_user_id, presence: true
  validates :played_at, presence: true
end
