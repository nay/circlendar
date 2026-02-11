class Admin::MembersController < Admin::BaseController
  before_action :set_member, only: %i[show edit update destroy]

  def index
    collection = Member.joins(:user)
                       .order(
                         Arel.sql("CASE users.role WHEN 'admin' THEN 0 ELSE 1 END"),
                         Arel.sql("users.last_accessed_at DESC NULLS LAST"),
                         Arel.sql("users.created_at DESC")
                       )
    @pagy, @members = pagy(:offset, collection, limit: 10)
  end

  def show
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params_for_create)
    @member.user.confirmed_at = Time.current

    if @member.save
      redirect_to admin_member_path(@member), notice: "#{Member.model_name.human}を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @member.user == Current.user && member_params[:disabled] == "1"
      redirect_to edit_admin_member_path(@member), alert: "自分自身は無効にできません"
      return
    end


    @member.assign_attributes(member_params)

    if @member.save
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
    permitted = params.require(:member).permit(:name, :email_address, :organization_name, :rank, :description, :receives_announcements, :disabled, :role, :password, :password_confirmation)
    if permitted[:password].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted.delete(:role) if @member.user == Current.user
    permitted
  end

  def member_params_for_create
    params.require(:member).permit(:name, :email_address, :organization_name, :rank, :description, :receives_announcements, :role, :password, :password_confirmation)
  end
end
