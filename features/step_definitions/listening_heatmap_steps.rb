require "ostruct"

Given("Spotify returns 3 recent plays across days") do
  base_date = Date.today
  plays = [
    OpenStruct.new(id: "t1", name: "One", artists: "A", played_at: base_date.to_time),
    OpenStruct.new(id: "t2", name: "Two", artists: "B", played_at: (base_date - 1).to_time),
    OpenStruct.new(id: "t3", name: "Three", artists: "C", played_at: (base_date - 2).to_time)
  ]

  allow_any_instance_of(SpotifyClient)
    .to receive(:recently_played)
    .and_return(plays)
end
