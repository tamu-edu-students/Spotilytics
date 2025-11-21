# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_21_200850) do
  create_table "track_search_results", force: :cascade do |t|
    t.integer "track_search_id", null: false
    t.integer "position", null: false
    t.string "spotify_id", null: false
    t.string "name", null: false
    t.string "artists"
    t.string "album_name"
    t.string "album_image_url"
    t.integer "popularity"
    t.string "preview_url"
    t.string "spotify_url"
    t.integer "duration_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["track_search_id"], name: "index_track_search_results_on_track_search_id"
  end

  create_table "track_searches", force: :cascade do |t|
    t.string "query", null: false
    t.integer "limit", default: 10, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "spotify_user_id"
    t.index ["query", "limit"], name: "index_track_searches_on_user_id_and_query_and_limit", unique: true
  end

  add_foreign_key "track_search_results", "track_searches"
end
