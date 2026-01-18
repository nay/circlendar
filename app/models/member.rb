class Member < Player
  belongs_to :user

  validates :user, presence: true

  delegate :email_address, :receives_announcements, :receives_announcements?, :disabled?, :admin?, to: :user

  def email_address=(value)
    user.email_address = value
  end

  def receives_announcements=(value)
    user.receives_announcements = value
  end

  def password=(value)
    user.password = value
  end

  def password_confirmation=(value)
    user.password_confirmation = value
  end

  def disabled=(value)
    self.user.disabled_at = (value == "1" || value == true) ? Time.current : nil
  end

  def disabled
    user.disabled?
  end

  def save_with_user
    transaction do
      user.save! && save!
    end
  rescue ActiveRecord::RecordInvalid
    false
  end
end
