class Admin::MembersController < Admin::BaseController
  before_action :set_member, only: %i[show destroy]

  def index
    @members = Member.includes(:user).order(:name)
  end

  def show
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
end
