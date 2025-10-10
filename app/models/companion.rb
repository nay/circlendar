class Companion < Player
  belongs_to :attendance

  validates :attendance, presence: true
end
