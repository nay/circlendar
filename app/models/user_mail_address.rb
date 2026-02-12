class UserMailAddress < ApplicationRecord
  MAX_PER_USER = 5

  belongs_to :user

  scope :confirmed, -> { where.not(confirmed_at: nil) }

  normalizes :address, with: ->(e) { e.strip.downcase }

  validates :address, presence: true, uniqueness: true
  validate :validate_count, on: :create

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
