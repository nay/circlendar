class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :member, dependent: :destroy

  enum :role, { admin: "admin", member: "member" }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
end
