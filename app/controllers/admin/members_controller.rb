class Admin::MembersController < Admin::BaseController
  before_action :set_member, only: %i[show edit update destroy]

  def index
    @members = Member.includes(:user).order(:name)
  end

  def show
  end

  def edit
  end

  def update
    if @member.user == Current.user && member_params[:disabled] == "1"
      redirect_to edit_admin_member_path(@member), alert: "自分自身は無効にできません"
      return
    end

    @member.assign_attributes(member_params)

    if @member.save_with_user
      redirect_to admin_member_path(@member), notice: "#{Member.model_name.human}を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @member.user == Current.user
      redirect_to admin_member_path(@member), alert: "自分自身は削除できません"
    else
      @member.user.destroy
      redirect_to admin_members_path, notice: "#{Member.model_name.human}を削除しました"
    end
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def member_params
    params.require(:member).permit(:name, :organization_name, :rank, :description, :receives_announcements, :disabled)
  end
end
