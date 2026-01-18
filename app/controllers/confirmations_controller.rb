class ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    user = User.active.find_by(confirmation_token: params[:token])

    if user
      user.confirm!
      start_new_session_for user
      redirect_to dashboard_path, notice: "メールアドレスの確認が完了しました"
    else
      redirect_to new_session_path, alert: "確認リンクが無効です"
    end
  end
end
