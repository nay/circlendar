class Member < Player
  validates :user, presence: true
end
