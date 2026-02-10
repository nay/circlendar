class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :redirect_to_primary_host

  helper_method :current_member

  private

    def redirect_to_primary_host
      return unless request.get? || request.head?

      primary_host = ENV["APP_HOST"]
      return unless primary_host.present?
      return if request.host == primary_host

      redirect_to "https://#{primary_host}#{request.fullpath}", status: :moved_permanently, allow_other_host: true
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || default_after_authentication_url
    end

    def default_after_authentication_url
      dashboard_path
    end

    def current_member
      @current_member ||= Current.user&.member
    end
end
