class NewReleaseBatch < ApplicationRecord
  has_many :new_releases, dependent: :destroy

  validates :limit,      presence: true
  validates :fetched_at, presence: true
end