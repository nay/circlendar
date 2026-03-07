class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user.assign_attributes(profile_params)

    if @user.save
      redirect_to edit_profile_path, notice: "プロフィールを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(
      :name, :organization_name, :rank, :description,
      :receives_announcements, :password, :password_confirmation
    )
  end
end
