require "ostruct"

Given("Spotify returns {int} recent plays across hours") do |count|
  base_time = Time.utc(2025, 1, 1, 12, 0, 0)

  plays = count.times.map do |i|
    OpenStruct.new(
      id: "t#{i}",
      name: "Track #{i}",
      artists: "Artist #{i}",
      played_at: base_time - i.hours
    )
  end

  allow_any_instance_of(SpotifyClient)
    .to receive(:recently_played)
    .and_return(plays)
end
