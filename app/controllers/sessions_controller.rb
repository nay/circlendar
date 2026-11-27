class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: I18n.t("sessions.rate_limit") }

  layout "authentication"

  def new
  end

  def create
    mail_address = UserMailAddress.authenticate(address: params[:email_address], password: params[:password])

    if mail_address.nil?
      redirect_to new_session_path, alert: I18n.t("sessions.create.failure")
    elsif mail_address.confirmed?
      start_new_session_for mail_address.user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: I18n.t("sessions.create.unconfirmed")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: I18n.t("sessions.destroy.success")
  end
end
