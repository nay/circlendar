class UserMailer < ApplicationMailer
  def confirmation(mail_address)
    @user = mail_address.user
    @confirmation_url = confirm_url(token: mail_address.confirmation_token)
    mail subject: "【#{Setting.instance.circle_name}】メールアドレスの確認", to: mail_address.address
  end
end
