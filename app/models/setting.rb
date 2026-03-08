class Setting < ApplicationRecord
  # シングルトンパターン: 1レコードのみ存在
  def self.instance
    first_or_create!(circle_name: "サークル名未設定")
  end

  validates :circle_name, presence: true
  validates :daily_mail_delivery_limit, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :daily_announcement_delivery_limit, presence: true, numericality: { only_integer: true, greater_than: 0 }

  def generate_signup_token!
    update!(signup_token: SecureRandom.urlsafe_base64(15))
  end
end
