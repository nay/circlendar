class UserMailAddress < ApplicationRecord
  belongs_to :user

  normalizes :address, with: ->(e) { e.strip.downcase }

  validates :address, presence: true, uniqueness: true

  def confirmed?
    confirmed_at.present?
  end

  def generate_confirmation_token!
    update!(confirmation_token: SecureRandom.urlsafe_base64(32))
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end
end
