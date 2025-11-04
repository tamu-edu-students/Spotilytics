# Class Diagram

```mermaid
classDiagram
  class ApplicationController

  class PagesController {
    +home()
    +dashboard()
    -spotify_client()
    -fetch_top_artists(limit, time_range = "long_term")
    -fetch_top_tracks(limit)
    -build_genre_chart!(artists)
  }

  class TopTracksController {
    +index()
    -normalize_limit(param)
    -require_spotify_auth!()
  }

  class PlaylistsController {
    +create()
    -require_spotify_auth!()
  }

  class SessionsController {
    +create()  /* /auth/spotify/callback */
    +destroy() /* logout */
  }

  class SpotifyClient {
    +initialize(session:)
    +top_tracks(limit:, time_range:)
    +top_artists(limit:, time_range:)
    +followed_artists(limit:)
    +search_tracks(query, limit:)
    +new_releases(limit:)
    +current_user_id()
    +create_playlist_for(user_id:, name:, description:, public:)
    +add_tracks_to_playlist(playlist_id:, uris:)
    +clear_user_cache()
    -cache_for(key_parts, expires_in)
    -ensure_access_token!()
    -refresh_access_token!()
    -get(path, token, params)
    -post_json(path, token, body)
    -request_with_json(klass, path, token, params, body)
  }

  class RailsCache {
    <<framework>>
    +fetch(key, expires_in, &block)
    +delete_matched(pattern)
  }

  class Track {
    +id : String
    +name : String
    +artists : String
    +album_name : String
    +album_image_url : String
    +popularity : Integer
    +preview_url : String
    +spotify_url : String
    +rank : Integer
    +duration_ms : Integer
  }

  class Artist {
    +id : String
    +name : String
    +image_url : String
    +genres : String[]
    +popularity : Integer
    +playcount : Integer
    +spotify_url : String
    +rank : Integer
  }

  class RedisStore {
    <<Heroku Add-on>>
    +GET/SET keys
    +TTL 24h
    +namespace "spotilytics-cache"
  }

  ApplicationController <|-- PagesController
  ApplicationController <|-- TopTracksController
  ApplicationController <|-- PlaylistsController
  ApplicationController <|-- SessionsController

  PagesController --> SpotifyClient
  TopTracksController --> SpotifyClient
  PlaylistsController --> SpotifyClient

  SpotifyClient --> Track
  SpotifyClient --> Artist

  %% Caching collaboration
  SpotifyClient --> RailsCache : uses (Rails.cache)
  RailsCache --> RedisStore : backed by