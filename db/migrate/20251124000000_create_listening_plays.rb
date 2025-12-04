class CreateListeningPlays < ActiveRecord::Migration[7.1]
  def change
    create_table :listening_plays do |t|
      t.string :spotify_user_id, null: false
      t.string :track_id
      t.string :track_name
      t.string :artists
      t.string :album_name
      t.string :album_image_url
      t.datetime :played_at, null: false
      t.string :preview_url
      t.string :spotify_url

      t.timestamps
    end

    add_index :listening_plays, [ :spotify_user_id, :track_id, :played_at ], unique: true, name: "index_listening_plays_on_user_track_played_at"
    add_index :listening_plays, [ :spotify_user_id, :played_at ]
  end
end
