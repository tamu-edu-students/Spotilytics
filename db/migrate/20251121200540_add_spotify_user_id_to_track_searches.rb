class AddSpotifyUserIdToTrackSearches < ActiveRecord::Migration[8.0]
  def change
    add_column :track_searches, :spotify_user_id, :string
  end
end
