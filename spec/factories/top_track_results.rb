FactoryBot.define do
  factory :top_track_result do
    top_track_batch { nil }
    position { 1 }
    spotify_id { "MyString" }
    name { "MyString" }
    artists { "MyString" }
    album_name { "MyString" }
    album_image_url { "MyString" }
    popularity { 1 }
    preview_url { "MyString" }
    spotify_url { "MyString" }
    duration_ms { 1 }
  end
end
