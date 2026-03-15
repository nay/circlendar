class LineLoginController < ApplicationController
  allow_unauthenticated_access

  def authorize
    state = SecureRandom.urlsafe_base64(32)
    session[:line_oauth_state] = state
    session[:line_oauth_context] = {
      type: params[:context],
      signup_token: params[:token]
    }

    client = LineClient.new
    redirect_to client.authorize_url(state: state, redirect_uri: line_login_callback_url), allow_other_host: true
  end

  def callback
    unless params[:state] == session.delete(:line_oauth_state)
      redirect_to new_session_path, alert: t("line_login.invalid_state")
      return
    end

    context = session.delete(:line_oauth_context) || {}

    client = LineClient.new
    access_token = client.get_access_token(code: params[:code], redirect_uri: line_login_callback_url)
    profile = client.get_profile(access_token)

    case context["type"]
    when "signup"
      handle_signup(profile, context["signup_token"])
    when "login"
      handle_login(profile)
    else
      redirect_to new_session_path, alert: t("line_login.invalid_context")
    end
  rescue => e
    Rails.logger.error("LINE login error: #{e.message}")
    redirect_to new_session_path, alert: t("line_login.error")
  end

  private

  def handle_signup(profile, signup_token)
    setting = Setting.instance
    unless setting.signup_token.present? && signup_token == setting.signup_token
      raise ActionController::RoutingError, "Not Found"
    end

    user = User.find_by(line_user_id: profile[:user_id])

    if user
      start_new_session_for(user)
      redirect_to root_path
    else
      user = User.create!(
        line_user_id: profile[:user_id],
        role: :member
      )
      start_new_session_for(user)
      redirect_to root_path
    end
  end

  def handle_login(profile)
    user = User.find_by(line_user_id: profile[:user_id])

    if user && !user.disabled?
      start_new_session_for(user)
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: t("line_login.user_not_found")
    end
  end
end
