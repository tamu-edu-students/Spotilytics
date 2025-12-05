require "ostruct"

Given("the playlist energy service returns sample points") do
  mock_service = instance_double(PlaylistEnergyService)
  allow(PlaylistEnergyService).to receive(:new).and_return(mock_service)

  allow(mock_service).to receive(:energy_profile).and_return([
    { label: "1. Track Alpha", energy: 75.0, track: OpenStruct.new(name: "Track Alpha", artists: "A") },
    { label: "2. Track Beta", energy: 42.5, track: OpenStruct.new(name: "Track Beta", artists: "B") }
  ])
end
