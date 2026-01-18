class Player < ApplicationRecord
  has_many :attendances, dependent: :destroy

  enum :rank, {
    e: "E",
    d: "D",
    c: "C",
    b: "B",
    a: "A",
    unknown: "不明"
  }, default: :e

  validates :name, presence: true

  def formatted_rank
    unknown? ? "不明" : "#{rank.upcase}級"
  end
end
