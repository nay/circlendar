require "rails_helper"

RSpec.describe "出欠回答", type: :system do
  let(:user) { create(:user) }
  let(:event) { create(:event, status: :published) }
  let(:other_member) { create(:member, name: "山田", organization_name: "山田将棋クラブ") }

  before do
    create(:attendance, event: event, player: other_member, status: :attending)
  end

  context "スマホの画面幅の場合" do
    before do
      driven_by :selenium, using: :headless_chrome, screen_size: [ 375, 812 ]
    end

    it "ログインして出欠を回答し、ログアウトできる" do
      sign_in_with_form(user)

      find("a[href='#{edit_event_attendance_path(event)}']", match: :first).click
      expect(page).to have_current_path(edit_event_attendance_path(event))

      find("label:has(#attendance_status_attending)").click
      expect(page).to have_css("label.border-blue-500:has(#attendance_status_attending)")
      expect(page).to have_css("label.border-gray-300:has(#attendance_status_not_attending)")

      expect(page).to have_no_text("山田将棋クラブ")
      click_button "山田"
      expect(page).to have_text("山田将棋クラブ")

      click_button "保存"
      expect(page).to have_text(I18n.t("messages.update.success", model: Attendance.model_name.human))
      expect(page).to have_text("参加")

      expect(page).to have_no_button("ログアウト")
      click_button user.name
      accept_confirm("ログアウトしますか？") do
        click_button "ログアウト"
      end
      expect(page).to have_current_path(new_session_path)
    end
  end
end
