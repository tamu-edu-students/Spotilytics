require "ostruct"

Given("Spotify returns recent plays across two months") do
  base_time = Time.utc(2025, 1, 15, 12, 0, 0)

  plays = [
    OpenStruct.new(
      id: "t-jan",
      name: "January Track",
      artists: "Artist A",
      played_at: base_time,
      duration_ms: 3_600_000 # 1 hour
    ),
    OpenStruct.new(
      id: "t-dec",
      name: "December Track",
      artists: "Artist B",
      played_at: base_time - 1.month,
      duration_ms: 7_200_000 # 2 hours
    )
  ]

  allow_any_instance_of(SpotifyClient)
    .to receive(:recently_played)
    .and_return(plays)
end
