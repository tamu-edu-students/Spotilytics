class CreateTopTrackResults < ActiveRecord::Migration[7.1]
  def change
    create_table :top_track_results do |t|
      t.references :top_track_batch, null: false, foreign_key: true
      t.integer    :position,        null: false
      t.string     :spotify_id,      null: false
      t.string     :name,            null: false
      t.string     :artists
      t.string     :album_name
      t.string     :album_image_url
      t.integer    :popularity
      t.string     :preview_url
      t.string     :spotify_url
      t.integer    :duration_ms

      t.timestamps
    end
  end
end
