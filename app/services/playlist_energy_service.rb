class PlaylistEnergyService
  def initialize(client:, features_client: ReccoBeatsClient)
    @client = client
    @features_client = features_client
  end

  def energy_profile(playlist_id:, limit: 100)
    tracks = client.playlist_tracks(playlist_id: playlist_id, limit: limit)
    return [] if tracks.blank?

    feature_map = fetch_feature_map(tracks.map(&:id))

    tracks.each_with_index.map do |track, idx|
      energy_raw = feature_map[track.id]
      {
        position: idx + 1,
        track: track,
        label: "#{idx + 1}. #{track.name}",
        energy: normalize_energy(energy_raw)
      }
    end
  end

  private

  attr_reader :client, :features_client

  def fetch_feature_map(track_ids)
    features = features_client.fetch_audio_features(track_ids) || []

    # Debug logging
    Rails.logger.info "[PlaylistEnergy] Fetched #{features.size} features for #{track_ids.size} tracks"

    features.each_with_object({}) do |feat, acc|
      # ReccoBeats returns hash with string keys
      spotify_id = feat["spotify_id"] || feat[:spotify_id]
      next unless spotify_id

      energy = feat["energy"] || feat[:energy]

      # Debug log each mapping
      Rails.logger.debug "[PlaylistEnergy] Mapping #{spotify_id} => #{energy}"

      acc[spotify_id] = energy
    end
  end

  def normalize_energy(value)
    return nil if value.nil?

    val = value.to_f
    val = val * 100 if val <= 1
    val = 0 if val.negative?
    val = 100 if val > 100
    val.round(1)
  end
end
