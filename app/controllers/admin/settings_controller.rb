class Admin::SettingsController < Admin::BaseController
  def edit
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance

    if @setting.update(setting_params)
      redirect_to edit_admin_setting_path, notice: "#{Setting.model_name.human}を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:circle_name)
  end
end
