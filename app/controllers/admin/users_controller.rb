class Admin::UsersController < Admin::BaseController
  before_action :set_member, only: %i[show edit update destroy]

  def index
    collection = Member.joins(:user).merge(User.ordered)
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
      redirect_to admin_user_path(@member), notice: "#{User.model_name.human}を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @member.user == Current.user && member_params[:disabled] == "1"
      redirect_to edit_admin_user_path(@member), alert: "自分自身は無効にできません"
      return
    end

    @member.assign_attributes(member_params)

    if params[:add_mail_address]
      @member.user.mail_addresses.build
      render :edit, status: :unprocessable_entity
      return
    end

    if params[:remove_mail_address]
      index = params[:remove_mail_address].to_i
      target = @member.user.mail_addresses.reject(&:marked_for_destruction?)[index]
      target&.mark_for_destruction
      render :edit, status: :unprocessable_entity
      return
    end

    @member.user.confirm_new_mail_addresses

    if @member.save
      redirect_to admin_user_path(@member), notice: "#{User.model_name.human}を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @member.user == Current.user
      redirect_to admin_user_path(@member), alert: "自分自身は削除できません"
    else
      @member.user.destroy
      redirect_to admin_users_path, notice: "#{User.model_name.human}を削除しました"
    end
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def member_params
    permitted = params.require(:member).permit(
      :name, :organization_name, :rank, :description, :receives_announcements,
      :disabled, :role, :password, :password_confirmation,
      mail_addresses_attributes: [ :id, :address, :_destroy ]
    )
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
