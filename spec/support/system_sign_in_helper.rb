module SystemSignInHelper
  def sign_in_with_form(user, password: "password123")
    visit new_session_path
    fill_in "メールアドレス", with: user.email_address
    fill_in "パスワード", with: password
    click_button "ログイン"
    expect(page).to have_current_path(root_path)
  end
end

RSpec.configure do |config|
  config.include SystemSignInHelper, type: :system
end
