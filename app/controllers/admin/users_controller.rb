class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[show]
  before_action :set_member, only: %i[edit update destroy]

  def index
    collection = User.ordered.includes(:member)
    @pagy, @users = pagy(:offset, collection, limit: 10)
  end

  def show
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params_for_create)
    @member.confirmed_at = Time.current

    if @member.save
      redirect_to admin_user_path(@member.user), notice: "#{User.model_name.human}を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user == Current.user && member_params[:disabled] == "1"
      redirect_to edit_admin_user_path(@user), alert: "自分自身は無効にできません"
      return
    end

    @member.assign_attributes(member_params)

    if params[:add_mail_address]
      @user.mail_addresses.build
      render :edit, status: :unprocessable_entity
      return
    end

    if params[:remove_mail_address]
      index = params[:remove_mail_address].to_i
      target = @user.mail_addresses.reject(&:marked_for_destruction?)[index]
      target&.mark_for_destruction
      render :edit, status: :unprocessable_entity
      return
    end

    @user.confirm_new_mail_addresses

    if @member.save
      redirect_to admin_user_path(@user), notice: "#{User.model_name.human}を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == Current.user
      redirect_to admin_user_path(@user), alert: "自分自身は削除できません"
    else
      @user.destroy
      redirect_to admin_users_path, notice: "#{User.model_name.human}を削除しました"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_member
    @user = User.find(params[:id])
    @member = @user.member
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
    permitted.delete(:role) if @user == Current.user
    permitted
  end

  def member_params_for_create
    params.require(:member).permit(:name, :email_address, :organization_name, :rank, :description, :receives_announcements, :role, :password, :password_confirmation)
  end
end
