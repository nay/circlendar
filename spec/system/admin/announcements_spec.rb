require "rails_helper"

RSpec.describe "お知らせの作成と削除", type: :system do
  let(:admin) { create(:user, :admin) }

  before do
    create(:user, email_address: "sato@example.com", member: build(:member, name: "佐藤"))
  end

  it "宛先を全解除・全選択して選び直し、作成したお知らせを確認ダイアログを経て削除できる" do
    sign_in_with_form(admin)

    visit admin_announcements_path
    click_link I18n.t("announcements.index.new_announcement")

    recipient_checkboxes = "input[name='announcement[recipient_user_ids][]'][type=checkbox]"
    expect(page).to have_css("#{recipient_checkboxes}:checked", count: 2)
    click_button "全解除"
    expect(page).to have_no_css("#{recipient_checkboxes}:checked")
    click_button "全選択"
    expect(page).to have_css("#{recipient_checkboxes}:checked", count: 2)
    click_button "全解除"
    check "佐藤"

    fill_in Announcement.human_attribute_name(:subject), with: "今週の練習会"
    fill_in Announcement.human_attribute_name(:body), with: "よろしくお願いします"
    click_button I18n.t("helpers.submit.announcement.create")

    expect(page).to have_text(I18n.t("messages.create.success", model: Announcement.model_name.human))
    within(find("dt", exact_text: Announcement.human_attribute_name(:recipient_addresses)).find(:xpath, "..")) do
      expect(page).to have_text("sato@example.com")
      expect(page).to have_no_text(admin.email_address)
    end

    accept_confirm(I18n.t("announcements.show.confirm_delete")) do
      click_button I18n.t("announcements.show.delete")
    end
    expect(page).to have_text(I18n.t("messages.destroy.success", model: Announcement.model_name.human))
    expect(page).to have_no_text("今週の練習会")
  end
end
