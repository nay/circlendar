class AddReferralLineSettingsToSettings < ActiveRecord::Migration[8.1]
  DEFAULT_REFERRAL_SHARE_TEMPLATE = <<~TEXT.strip
    %{circle_name}に練習に来ませんか？
    練習会のお知らせはLINE公式アカウントから受け取れます:
    %{line_url}

    すぐ登録するならこちら:
    %{signup_url}
  TEXT

  def up
    add_column :settings, :line_official_account_url, :string
    add_column :settings, :referral_share_template, :text, default: DEFAULT_REFERRAL_SHARE_TEMPLATE

    # 既存レコードにデフォルト値を反映
    Setting.reset_column_information
    Setting.where(referral_share_template: nil).update_all(referral_share_template: DEFAULT_REFERRAL_SHARE_TEMPLATE)
  end

  def down
    remove_column :settings, :referral_share_template
    remove_column :settings, :line_official_account_url
  end
end
