class ChangeRankDefaultInPlayers < ActiveRecord::Migration[8.1]
  def change
    Player.where(rank: nil).update_all(rank: "不明")
    change_column_default :players, :rank, from: nil, to: "不明"
    change_column_null :players, :rank, false
  end
end
