class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "【#{Setting.instance.circle_name}】パスワードリセット", to: user.email_address
  end
end
