class CreateTrackSearches < ActiveRecord::Migration[7.1]
  def change
    create_table :track_searches do |t|
      t.references :user, null: false, foreign_key: true   # or remove if no users
      t.string :query, null: false
      t.integer :limit, null: false, default: 10
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :track_searches, [:user_id, :query, :limit], unique: true
  end
end