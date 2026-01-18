class Admin::MembersController < Admin::BaseController
  def index
    @members = Member.includes(:user).order(:name)
  end
end
