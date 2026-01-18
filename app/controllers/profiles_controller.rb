class ProfilesController < ApplicationController
  def edit
    @member = current_member
  end

  def update
    @member = current_member
    @member.assign_attributes(profile_params)

    if @member.save
      redirect_to edit_profile_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    permitted = params.require(:member).permit(
      :name, :email_address, :organization_name, :rank, :description,
      :receives_announcements, :password, :password_confirmation
    )
    if permitted[:password].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted
  end
end
