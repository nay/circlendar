class User < ApplicationRecord
  has_secure_password

  has_one :member, dependent: :destroy

  enum :role, { admin: "admin", member: "member" }

  validates :email, presence: true, uniqueness: true
end
