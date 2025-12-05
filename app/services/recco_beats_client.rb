require "net/http"
require "uri"
require "json"

class ReccoBeatsClient
  BASE_URL = "https://api.reccobeats.com/v1"

  def self.fetch_audio_features(ids)
    return [] if ids.blank?

    query = URI.encode_www_form(ids: ids)
    url   = URI("#{BASE_URL}/audio-features?#{query}")

    response = Net::HTTP.get_response(url)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "[ReccoBeats] API error: #{response.code} – #{response.body}"
      return []
    end

    body = JSON.parse(response.body)

    raw_features = body["content"] || []

    raw_features.map do |f|
      href = f["href"]
      spotify_id =
        if href.present?
          href.split("/").last
        end

      f.merge("spotify_id" => spotify_id)
    end

  rescue => e
    Rails.logger.error "[ReccoBeats] Exception: #{e.class} – #{e.message}"
    []
  end
end
