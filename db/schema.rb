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

ActiveRecord::Schema[8.0].define(version: 2025_11_23_234244) do
  create_table "followed_artist_batches", force: :cascade do |t|
    t.string "spotify_user_id"
    t.integer "limit"
    t.datetime "fetched_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "followed_artists", force: :cascade do |t|
    t.integer "followed_artist_batch_id", null: false
    t.string "spotify_id"
    t.string "name"
    t.string "image_url"
    t.integer "popularity"
    t.string "spotify_url"
    t.text "genres"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_artist_batch_id"], name: "index_followed_artists_on_followed_artist_batch_id"
  end

  create_table "new_release_batches", force: :cascade do |t|
    t.integer "limit", default: 10, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["limit"], name: "index_new_release_batches_on_limit", unique: true
  end

  create_table "new_releases", force: :cascade do |t|
    t.integer "new_release_batch_id", null: false
    t.integer "position", null: false
    t.string "spotify_id", null: false
    t.string "name", null: false
    t.string "image_url"
    t.integer "total_tracks"
    t.string "release_date"
    t.string "spotify_url"
    t.text "artists"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["new_release_batch_id", "position"], name: "index_new_releases_on_batch_and_position", unique: true
    t.index ["new_release_batch_id"], name: "index_new_releases_on_new_release_batch_id"
  end

  create_table "top_artist_batches", force: :cascade do |t|
    t.string "spotify_user_id", null: false
    t.string "time_range", null: false
    t.integer "limit", default: 20, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_user_id", "time_range", "limit"], name: "index_top_artist_batches_user_range_limit", unique: true
  end

  create_table "top_artist_results", force: :cascade do |t|
    t.integer "top_artist_batch_id", null: false
    t.integer "position", null: false
    t.string "spotify_id", null: false
    t.string "name", null: false
    t.string "image_url"
    t.text "genres"
    t.integer "popularity"
    t.integer "playcount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["top_artist_batch_id"], name: "index_top_artist_results_on_top_artist_batch_id"
  end

  create_table "top_track_batches", force: :cascade do |t|
    t.string "spotify_user_id", null: false
    t.string "time_range", null: false
    t.integer "limit", default: 20, null: false
    t.datetime "fetched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spotify_user_id", "time_range", "limit"], name: "index_top_track_batches_user_range_limit", unique: true
  end

  create_table "top_track_results", force: :cascade do |t|
    t.integer "top_track_batch_id", null: false
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
    t.index ["top_track_batch_id"], name: "index_top_track_results_on_top_track_batch_id"
  end

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
    t.index ["spotify_user_id", "query", "limit"], name: "index_track_searches_on_user_and_query_and_limit"
  end

  add_foreign_key "followed_artists", "followed_artist_batches"
  add_foreign_key "new_releases", "new_release_batches"
  add_foreign_key "top_artist_results", "top_artist_batches"
  add_foreign_key "top_track_results", "top_track_batches"
  add_foreign_key "track_search_results", "track_searches"
end
