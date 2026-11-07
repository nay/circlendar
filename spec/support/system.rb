module SystemDriverHelper
  # 画面幅はブラウザを起動したときにだけ設定されるので、幅ごとに別の名前のドライバにする
  def driven_by_headless_chrome(screen_size:, name: :selenium)
    driven_by(:selenium, using: :headless_chrome, screen_size: screen_size, options: { name: name }) do |options|
      options.add_preference("profile.password_manager_leak_detection", false) # 漏洩パスワードの警告ダイアログが操作を横取りするため
    end
  end
end

RSpec.configure do |config|
  config.include SystemDriverHelper, type: :system

  config.before(:each, type: :system) do
    driven_by_headless_chrome(screen_size: [ 1400, 1400 ])
  end
end
