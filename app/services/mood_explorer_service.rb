class MoodExplorerService
  MOOD_GROUPS =
{
    hype:      ->(f) { f["energy"].to_f > 0.7 && f["valence"].to_f > 0.6 },
    party:     ->(f) { f["danceability"].to_f > 0.7 && f["energy"].to_f > 0.6 && f["valence"].to_f > 0.5 },
    chill:     ->(f) { f["energy"].to_f < 0.5 && f["valence"].to_f >= 0.5 },
    sad:       ->(f) { f["energy"].to_f < 0.6 && f["valence"].to_f < 0.4 },
    aggressive: ->(f) { f["energy"].to_f > 0.7 && f["valence"].to_f < 0.4 }
}

  def initialize(top_tracks, features)
    @top_tracks = top_tracks
    @features   = features.index_by { |f| f["spotify_id"] }
  end

  def self.detect_single(features_hash)
    return :misc unless features_hash

    MOOD_GROUPS.each do |name, rule|
      return name if rule.call(features_hash)
    end

    :misc
  end

  def clustered
    clusters = Hash.new { |h, k| h[k] = [] }

    @top_tracks.each do |track|
      feat = @features[track.id]
      next unless feat

      mood = detect_mood(feat)
      clusters[mood] << { track: track, features: feat }
    end

    clusters
  end

  private

  def detect_mood(feat)
    MOOD_GROUPS.each do |name, rule|
      return name if rule.call(feat)
    end
    :misc
  end
end
