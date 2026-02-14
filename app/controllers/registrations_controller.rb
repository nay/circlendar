class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create confirmation_sent]
  before_action :verify_signup_token, only: %i[new create]

  layout "authentication"

  def new
    if authenticated?
      redirect_to after_authentication_url, allow_other_host: true
      return
    end

    @user = User.new
    @user.build_member
  end

  def create
    existing_mail_address = UserMailAddress.find_by(address: user_params[:email_address])

    if existing_mail_address
      existing_user = existing_mail_address.user

      if existing_user.last_accessed_at.present?
        redirect_to new_session_path(email_address: existing_mail_address.address),
                    notice: "このメールアドレスはすでに登録されています。ログインしてください。"
        return
      end

      @user = existing_user
      @user.assign_attributes(user_params.except(:email_address))
      @user.role = :member

      if @user.save
        existing_mail_address.update!(confirmed_at: nil)
        send_confirmation_and_redirect(existing_mail_address) and return
      else
        render :new, status: :unprocessable_entity
      end
    else
      @user = User.new
      @user.build_member
      @user.assign_attributes(user_params)
      @user.role = :member

      if @user.save
        send_confirmation_and_redirect(@user.mail_addresses.first) and return
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def confirmation_sent
  end

  private

  def send_confirmation_and_redirect(mail_address)
    mail_address.generate_confirmation_token!
    UserMailer.confirmation(mail_address).deliver_later
    redirect_to confirmation_sent_path
  end

  def verify_signup_token
    setting = Setting.instance
    unless setting.signup_token.present? && params[:token] == setting.signup_token
      raise ActionController::RoutingError, "Not Found"
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :receives_announcements,
                                 :name, :organization_name, :rank, :description)
  end
end
