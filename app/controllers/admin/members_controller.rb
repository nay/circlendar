class Admin::MembersController < Admin::BaseController
  before_action :set_member, only: %i[show]

  def index
    @members = Member.includes(:user).order(:name)
  end

  def show
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end
end
