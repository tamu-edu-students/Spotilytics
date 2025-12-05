require "net/http"
require "uri"
require "json"

class ReccoBeatsClient
  BASE_URL = "https://api.reccobeats.com/v1"

  def self.fetch_audio_features(ids)
    return [] if ids.blank?

    # ReccoBeats API limits to 40 IDs per request, so batch them
    all_features = []
    Array(ids).each_slice(40) do |batch|
      batch_features = fetch_audio_features_batch(batch)
      all_features.concat(batch_features)
    end

    all_features
  rescue => e
    Rails.logger.error "[ReccoBeats] Exception: #{e.class} – #{e.message}"
    []
  end

  def self.fetch_audio_features_batch(ids)
    return [] if ids.blank?

    query = URI.encode_www_form(ids: ids.join(","))
    url   = URI("#{BASE_URL}/audio-features?#{query}")

    response = with_http(url) do |http|
      http.get(url.request_uri)
    end

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
    Rails.logger.error "[ReccoBeats] Batch exception: #{e.class} - #{e.message}"
    []
  end
  private_class_method :fetch_audio_features_batch

  def self.with_http(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == "https"
    http.verify_mode = ssl_verify_mode
    http.cert_store = build_cert_store

    yield http
  end
  private_class_method :with_http

  def self.ssl_verify_mode
    if ENV["RECCOBEATS_DISABLE_SSL_VERIFY"] == "true"
      OpenSSL::SSL::VERIFY_NONE
    else
      OpenSSL::SSL::VERIFY_PEER
    end
  end
  private_class_method :ssl_verify_mode

  def self.build_cert_store
    store = OpenSSL::X509::Store.new
    store.set_default_paths
    ca_file = ENV["RECCOBEATS_CA_FILE"]
    store.add_file(ca_file) if ca_file.present? && File.exist?(ca_file)
    store
  end
  private_class_method :build_cert_store
end
