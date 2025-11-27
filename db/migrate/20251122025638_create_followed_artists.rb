class CreateFollowedArtists < ActiveRecord::Migration[8.0]
  def change
    create_table :followed_artists do |t|
      t.references :followed_artist_batch, null: false, foreign_key: true
      t.string :spotify_id
      t.string :name
      t.string :image_url
      t.integer :popularity
      t.string :spotify_url
      t.text :genres
      t.integer :position

      t.timestamps
    end
  end
end
