class MusicPersonality
  Persona = Struct.new(:title, :subtitle, :traits, :hour_focus, :basis, keyword_init: true)

  attr_reader :features, :hour_counts

  def initialize(features:, hour_counts:)
    @features = Array(features)
    @hour_counts = hour_counts || {}
  end

  def summary
    Persona.new(
      title: headline,
      subtitle: subtitle,
      traits: traits,
      hour_focus: daypart_label,
      basis: basis_text
    )
  end

  def stats
    return {} if features.empty?
    {
      energy: avg(:energy),
      danceability: avg(:danceability),
      valence: avg(:valence),
      tempo: avg(:tempo),
      acousticness: avg(:acousticness),
      instrumentalness: avg(:instrumentalness)
    }
  end

  private

  def headline
    [daypart_title, energy_title].compact.join(" ")
  end

  def subtitle
    "#{mood_title} with a #{tempo_title} groove."
  end

  def traits
    [dance_title, acoustic_title, instrumental_title].compact
  end

  def basis_text
    "Based on audio features from #{features.count} tracks and recent listening hours."
  end

  def avg(key)
    return 0 if features.empty?
    values = features.map { |f| f.respond_to?(key) ? f.public_send(key) : f[key] }.compact.map(&:to_f)
    return 0 if values.empty?
    values.sum / values.size.to_f
  end

  def energy_title
    e = avg(:energy)
    return "High-Energy Listener" if e >= 0.7
    return "Chill Explorer" if e <= 0.4
    "Balanced Vibes"
  end

  def mood_title
    v = avg(:valence)
    return "sunny optimist" if v >= 0.65
    return "moody daydreamer" if v <= 0.35
    "mixed-mood listener"
  end

  def dance_title
    d = avg(:danceability)
    return "Dancefloor-ready" if d >= 0.7
    return "Introspective grooves" if d <= 0.4
    "Easy mover"
  end

  def tempo_title
    t = avg(:tempo)
    return "fast-paced" if t >= 130
    return "laid-back" if t <= 90
    "steady"
  end

  def acoustic_title
    a = avg(:acousticness)
    return "Organic/acoustic lean" if a >= 0.6
    return "Electronic edge" if a <= 0.2
    nil
  end

  def instrumental_title
    i = avg(:instrumentalness)
    return "Instrumental-friendly" if i >= 0.5
    nil
  end

  def daypart_label
    counts = {
      "Night Owl" => hours_sum(0..5),
      "Early Bird" => hours_sum(6..11),
      "Daytime" => hours_sum(12..17),
      "Evening" => hours_sum(18..23)
    }
    counts.max_by { |_k, v| v.to_i }&.first || "Anytime"
  end

  def daypart_title
    case daypart_label
    when "Night Owl" then "Night Owl"
    when "Early Bird" then "Early Bird"
    when "Evening" then "Evening Groover"
    when "Daytime" then "Daytime Drifter"
    else nil
    end
  end

  def hours_sum(range)
    range.to_a.sum { |h| hour_counts[h].to_i }
  end
end
