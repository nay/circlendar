class UserMailAddress < ApplicationRecord
  MAX_PER_USER = 5

  belongs_to :user

  normalizes :address, with: ->(e) { e.strip.downcase }

  validates :address, presence: true, uniqueness: true
  validate :validate_count, on: :create

  # 確認されていないアドレスも返すので、ログインさせる前に confirmed? を確かめる
  def self.find_with_correct_password(address:, password:)
    return nil if password.nil? || password.empty?

    mail_address = eager_load(:user).find_by(address:) # アドレスの有無でクエリの本数が変わらないよう、user も同じクエリで読む
    user = mail_address&.user
    if user&.password_digest.present?
      mail_address if user.authenticate(password) && !user.disabled?
    else
      User.new(password:) # 該当なし・仮登録でも bcrypt を1回計算し、応答時間からアドレスの有無や状態を推し量れないようにする
      nil
    end
  end

  def confirmed?
    confirmed_at.present?
  end

  def generate_confirmation_token!
    update!(confirmation_token: SecureRandom.urlsafe_base64(32))
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  private

  def validate_count
    if user && user.mail_addresses.reject(&:marked_for_destruction?).size > MAX_PER_USER
      errors.add(:base, "メールアドレスは#{MAX_PER_USER}件までです")
    end
  end
end
