class RemoveUserReferenceFromTrackSearches < ActiveRecord::Migration[7.0]
  def change
    if foreign_key_exists?(:track_searches, :users)
      remove_foreign_key :track_searches, :users
    end

    if column_exists?(:track_searches, :user_id)
      remove_column :track_searches, :user_id
    end
  end
end
