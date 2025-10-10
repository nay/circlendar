class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_member

  private
    def after_authentication_url
      if Current.user&.admin?
        admin_events_path
      else
        dashboard_path
      end
    end

    def current_member
      @current_member ||= Current.user&.member
    end
end
