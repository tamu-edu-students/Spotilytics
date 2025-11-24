class CreateFollowedArtistBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :followed_artist_batches do |t|
      t.string :spotify_user_id
      t.integer :limit
      t.datetime :fetched_at

      t.timestamps
    end
  end
end
