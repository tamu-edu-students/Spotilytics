Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Pages
  get "/dashboard",         to: "pages#dashboard",       as: :dashboard
  get "/top-artists",       to: "pages#top_artists",     as: :top_artists
  get "/home",              to: "pages#home",            as: :home
  get "/view-profile",      to: "pages#view_profile",    as: :view_profile
  get "/clear",             to: "pages#clear",           as: :clear
  get "/listening-patterns", to: "listening_patterns#hourly", as: :listening_patterns
  root "pages#home"

  # Spotify Authentication
  match "/auth/spotify/callback", to: "sessions#create", via: %i[get post]
  get    "/auth/failure",         to: "sessions#failure"
  get    "/login",                to: redirect("/auth/spotify"), as: :login
  delete "/logout",               to: "sessions#destroy",        as: :logout

  # Follow Artists
  resources :artist_follows, only: [ :create, :destroy ], param: :spotify_id

  # Top Tracks
  get  "/top_tracks",     to: "top_tracks#index", as: :top_tracks
  post "/create_playlist", to: "playlists#create", as: :create_playlist

  # Recommendations
  get  "/recommendations", to: "recommendations#recommendations", as: :recommendations

  # Playlists (ONLY KEEP THIS BLOCK)
  resources :playlists, only: [ :index, :create ] do
    member do
      get  :sort
      post :create_genre_playlists
    end
  end

  # Search
  get "/search", to: "search#index", as: :search

  # Wrapped
  get "/wrapped", to: "pages#wrapped", as: :wrapped
end
