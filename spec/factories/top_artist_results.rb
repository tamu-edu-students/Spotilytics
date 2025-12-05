FactoryBot.define do
  factory :top_artist_result do
    top_artist_batch { nil }
    position { 1 }
    spotify_id { "MyString" }
    name { "MyString" }
    image_url { "MyString" }
    genres { "MyText" }
    popularity { 1 }
    playcount { 1 }
  end
end
