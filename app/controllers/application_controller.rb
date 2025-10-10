class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
    def after_authentication_url
      if Current.user&.admin?
        admin_events_path
      else
        dashboard_path
      end
    end
end
