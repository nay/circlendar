class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :member, dependent: :destroy

  enum :role, { admin: "admin", member: "member" }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  scope :active, -> { where(disabled_at: nil) }
  scope :receives_announcements, -> { where(receives_announcements: true) }

  def confirmed?
    confirmed_at.present?
  end

  def disabled?
    disabled_at.present?
  end

  def generate_confirmation_token!
    update!(confirmation_token: SecureRandom.urlsafe_base64(32))
  end

  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end
end
