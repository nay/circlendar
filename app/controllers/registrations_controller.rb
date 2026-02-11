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
    @member = Member.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :member

    @member = @user.build_member(member_params)

    if @user.save
      mail_address = @user.mail_addresses.first
      mail_address.generate_confirmation_token!
      UserMailer.confirmation(mail_address).deliver_later
      redirect_to confirmation_sent_path
    else
      @member.valid?
      render :new, status: :unprocessable_entity
    end
  end

  def confirmation_sent
  end

  private

  def verify_signup_token
    setting = Setting.instance
    unless setting.signup_token.present? && params[:token] == setting.signup_token
      raise ActionController::RoutingError, "Not Found"
    end
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :receives_announcements)
  end

  def member_params
    params.require(:member).permit(:name, :organization_name, :rank, :description)
  end
end
