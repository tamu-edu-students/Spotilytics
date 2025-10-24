require 'net/http'
# frozen_string_literal: true

require 'uri'
require 'json'
require 'base64'
require 'ostruct'

class SpotifyClient
  API_ROOT = 'https://api.spotify.com/v1'
  TOKEN_URI = URI('https://accounts.spotify.com/api/token').freeze

  class Error < StandardError; end
  class UnauthorizedError < Error; end

  def initialize(session:)
    @session = session
    @client_id = ENV['SPOTIFY_CLIENT_ID']
    @client_secret = ENV['SPOTIFY_CLIENT_SECRET']
  end

  def top_artists(limit:, time_range:)
    access_token = ensure_access_token!
    response = get('/me/top/artists', access_token, limit: limit, time_range: time_range)
    items = response.fetch('items', [])
    items.map.with_index(1) do |item, index|
      OpenStruct.new(
        id: item['id'],
        name: item['name'],
        rank: index,
        image_url: item.dig('images', 0, 'url'),
        genres: item['genres'] || [],
        popularity: item['popularity'] || 0,
        playcount: item['popularity'] || 0
      )
    end
  end

  def top_tracks(limit:, time_range:)
    access_token = ensure_access_token!
    response = get('/me/top/tracks', access_token, limit: limit, time_range: time_range)
    items = response.fetch('items', [])

    items.map.with_index(1) do |item, index|
      OpenStruct.new(
        id: item['id'],
        name: item['name'],
        rank: index,
        artists: (item['artists'] || []).map { |a| a['name'] }.join(', '),
        album_name: item.dig('album', 'name'),
        album_image_url: item.dig('album', 'images', 0, 'url'),
        popularity: item['popularity'],
        preview_url: item['preview_url'],
        spotify_url: item.dig('external_urls', 'spotify'),
        duration_ms: item['duration_ms']
      )
    end
  end

  private

  attr_reader :session, :client_id, :client_secret

  def ensure_access_token!
    token = session[:spotify_token]
    return token if token.present? && !token_expired?

    refresh_access_token!
  end

  def token_expired?
    expires_at = session[:spotify_expires_at]
    return true unless expires_at

    Time.at(expires_at.to_i) <= Time.current + 30
  end

  def refresh_access_token!
    refresh_token = session[:spotify_refresh_token]
    raise UnauthorizedError, 'Missing Spotify refresh token' if refresh_token.blank?
    raise UnauthorizedError, 'Missing Spotify client credentials' if client_id.blank? || client_secret.blank?

    response = post_form(
      TOKEN_URI,
      {
        grant_type: 'refresh_token',
        refresh_token: refresh_token
      },
      token_headers
    )

    unless response['access_token']
      message = response['error_description'] || response.dig('error', 'message') || 'Unknown error refreshing token'
      raise UnauthorizedError, message
    end

    session[:spotify_token] = response['access_token']
    session[:spotify_expires_at] = Time.current.to_i + response.fetch('expires_in', 3600).to_i
    session[:spotify_refresh_token] = response['refresh_token'] if response['refresh_token'].present?

    session[:spotify_token]
  end

  def get(path, access_token, params = {})
    uri = URI.parse("#{API_ROOT}#{path}")
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['Content-Type'] = 'application/json'

    perform_request(uri, request)
  end

  def post_form(uri, params = {}, headers = {})
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)
    headers.each { |key, value| request[key] = value }

    perform_request(uri, request)
  end

  def perform_request(uri, request)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.open_timeout = 5
      http.read_timeout = 5
      http.request(request)
    end

    body = parse_json(response.body)

    if response.code.to_i >= 400
      message = body['error_description'] || body.dig('error', 'message') || response.message
      raise Error, message
    end

    body
  rescue SocketError, Errno::ECONNREFUSED, Net::OpenTimeout, Net::ReadTimeout => e
    raise Error, e.message
  end

  def parse_json(payload)
    return {} if payload.nil? || payload.empty?

    JSON.parse(payload)
  rescue JSON::ParserError
    {}
  end

  def token_headers
    encoded = Base64.strict_encode64("#{client_id}:#{client_secret}")
    {
      'Authorization' => "Basic #{encoded}",
      'Content-Type' => 'application/x-www-form-urlencoded'
    }
  end
end
