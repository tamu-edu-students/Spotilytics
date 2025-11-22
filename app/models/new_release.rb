class NewRelease < ApplicationRecord
  belongs_to :new_release_batch

  validates :position,   presence: true
  validates :spotify_id, presence: true
  validates :name,       presence: true
end