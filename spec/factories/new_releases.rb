FactoryBot.define do
  factory :new_release do
    new_release_batch { nil }
    position { 1 }
    spotify_id { "MyString" }
    name { "MyString" }
    image_url { "MyString" }
    total_tracks { 1 }
    release_date { "MyString" }
    spotify_url { "MyString" }
    artists { "MyText" }
  end
end
