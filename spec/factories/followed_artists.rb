FactoryBot.define do
  factory :followed_artist do
    followed_artist_batch { nil }
    spotify_id { "MyString" }
    name { "MyString" }
    image_url { "MyString" }
    popularity { 1 }
    spotify_url { "MyString" }
    genres { "MyText" }
    position { 1 }
  end
end
