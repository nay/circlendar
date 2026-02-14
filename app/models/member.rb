class Member < Player
  belongs_to :user

  validates :user, presence: true

  delegate :email_address, :email_address=,
           :receives_announcements, :receives_announcements=, :receives_announcements?,
           :password=, :password_confirmation=,
           :role, :role=,
           :confirmed_at, :confirmed_at=,
           :disabled?, :admin?,
           :mail_addresses_attributes=,
           to: :user

  def user
    super || build_user
  end

  def disabled=(value)
    self.user.disabled_at = (value == "1" || value == true) ? Time.current : nil
  end

  def disabled
    user.disabled?
  end
end
