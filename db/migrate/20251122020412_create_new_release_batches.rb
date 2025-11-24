class CreateNewReleaseBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :new_release_batches do |t|
      t.integer  :limit,      null: false, default: 10
      t.datetime :fetched_at, null: false

      t.timestamps
    end

    add_index :new_release_batches, :limit, unique: true
  end
end
