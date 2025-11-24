class FixTrackSearchesUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :track_searches, name: "index_track_searches_on_user_id_and_query_and_limit"

    add_index :track_searches,
              [:spotify_user_id, :query, :limit],
              unique: true,
              name: "index_track_searches_on_user_and_query_and_limit"
  end
end