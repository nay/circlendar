class ChangeRankNullableOnPlayers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :players, :rank, true
    change_column_default :players, :rank, from: "不明", to: nil
  end
end
