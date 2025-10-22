class PagesController < ApplicationController
    before_action :require_login, only: [:dashboard]

    def home
    end

    def dashboard
    end

    # Redirect users to the login page if they are not signed in
  def require_login
    unless current_user
      redirect_to home_path, alert: "You must log in with spotify to access the dashboard."
    end
  end
end