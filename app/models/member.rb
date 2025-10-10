class Member < Player
  belongs_to :user

  validates :user, presence: true
end
