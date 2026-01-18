class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create confirmation_sent]

  layout "authentication"

  def new
    @user = User.new
    @member = Member.new
  end

  def create
    @user = User.new(user_params)
    @user.role = :member

    @member = @user.build_member(member_params)

    if @user.save
      @user.generate_confirmation_token!
      UserMailer.confirmation(@user).deliver_later
      redirect_to confirmation_sent_path
    else
      @member.valid?
      render :new, status: :unprocessable_entity
    end
  end

  def confirmation_sent
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :receives_announcements)
  end

  def member_params
    params.require(:member).permit(:name, :organization_name, :rank, :description)
  end
end
