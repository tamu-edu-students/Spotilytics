class CreateTopArtistResults < ActiveRecord::Migration[7.1]
  def change
    create_table :top_artist_results do |t|
      t.references :top_artist_batch, null: false, foreign_key: true
      t.integer    :position,         null: false
      t.string     :spotify_id,       null: false
      t.string     :name,             null: false
      t.string     :image_url
      t.text       :genres
      t.integer    :popularity
      t.integer    :playcount

      t.timestamps
    end
  end
end