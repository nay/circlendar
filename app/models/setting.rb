class Setting < ApplicationRecord
  # シングルトンパターン: 1レコードのみ存在
  def self.instance
    first_or_create!(circle_name: "サークル名未設定")
  end

  validates :circle_name, presence: true
  validates :announcement_batch_size, :announcement_daily_quota_threshold, :announcement_retry_interval_hours,
            numericality: { greater_than: 0, only_integer: true }

  def generate_signup_token!
    update!(signup_token: SecureRandom.urlsafe_base64(15))
  end
end
