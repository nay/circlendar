class UserMailer < ApplicationMailer
  def confirmation(user)
    @user = user
    @confirmation_url = confirm_url(token: user.confirmation_token)
    mail subject: "【#{Setting.instance.circle_name}】メールアドレスの確認", to: user.email_address
  end
end
