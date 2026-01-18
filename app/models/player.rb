class Player < ApplicationRecord
  has_many :attendances, dependent: :destroy

  enum :rank, {
    unknown: "不明",
    f: "F",
    e: "E",
    d: "D",
    c: "C",
    b: "B",
    a: "A"
  }

  validates :name, presence: true

  def formatted_rank
    return nil if rank.nil?
    unknown? ? "不明（初心者）" : "#{rank.upcase}級"
  end
end
