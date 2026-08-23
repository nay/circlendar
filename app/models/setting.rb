class Setting < ApplicationRecord
  DEFAULT_REFERRAL_SHARE_TEMPLATE = <<~TEXT.strip
    %{circle_name}に練習に来ませんか？
    練習会のお知らせはLINE公式アカウントから受け取れます:
    %{line_url}

    すぐ登録するならこちら:
    %{signup_url}
  TEXT

  # シングルトンパターン: 1レコードのみ存在
  def self.instance
    Current.setting ||= first_or_create!(circle_name: "サークル名未設定")
  end

  validates :circle_name, presence: true
  validates :announcement_batch_size, :announcement_daily_quota_threshold, :announcement_retry_interval_hours,
            numericality: { greater_than: 0, only_integer: true }

  def generate_signup_token!
    update!(signup_token: SecureRandom.urlsafe_base64(15))
  end

  def referral_share_text(circle_name:, signup_url:, line_url:)
    return "" if referral_share_template.blank?
    referral_share_template
      .gsub("%{circle_name}", circle_name.to_s)
      .gsub("%{signup_url}", signup_url.to_s)
      .gsub("%{line_url}", line_url.to_s)
  end
end
