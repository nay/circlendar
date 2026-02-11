class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: I18n.t("sessions.rate_limit") }

  layout "authentication"

  def new
  end

  def create
    mail_address = UserMailAddress.find_by(address: params[:email_address])
    user = mail_address&.user

    if user && !user.disabled? && user.authenticate(params[:password])
      if mail_address.confirmed?
        start_new_session_for user
        redirect_to after_authentication_url
      else
        redirect_to new_session_path, alert: "メールアドレスが確認されていません。確認メールのリンクをクリックしてください。"
      end
    else
      # タイミング攻撃対策: ユーザーが見つからない場合もbcryptハッシュ計算を実行し、
      # ユーザーの有無で応答時間が変わらないようにする
      User.new(password: params[:password]) unless user
      redirect_to new_session_path, alert: I18n.t("sessions.create.failure")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: I18n.t("sessions.destroy.success")
  end
end
