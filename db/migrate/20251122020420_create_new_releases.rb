class CreateNewReleases < ActiveRecord::Migration[7.1]
  def change
    create_table :new_releases do |t|
      t.references :new_release_batch, null: false, foreign_key: true
      t.integer    :position,          null: false
      t.string     :spotify_id,        null: false
      t.string     :name,              null: false
      t.string     :image_url
      t.integer    :total_tracks
      t.string     :release_date
      t.string     :spotify_url
      t.text       :artists

      t.timestamps
    end

    add_index :new_releases, [ :new_release_batch_id, :position ],
              unique: true,
              name: "index_new_releases_on_batch_and_position"
  end
end
