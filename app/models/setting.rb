class Setting < ApplicationRecord
  # シングルトンパターン: 1レコードのみ存在
  def self.instance
    first_or_create!(circle_name: "サークル名未設定")
  end

  validates :circle_name, presence: true
end
