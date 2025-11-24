class CreateTopTrackBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :top_track_batches do |t|
      t.string   :spotify_user_id, null: false
      t.string   :time_range,      null: false
      t.integer  :limit,           null: false, default: 20
      t.datetime :fetched_at,      null: false

      t.timestamps
    end

    add_index :top_track_batches,
              [ :spotify_user_id, :time_range, :limit ],
              unique: true,
              name: "index_top_track_batches_user_range_limit"
  end
end
