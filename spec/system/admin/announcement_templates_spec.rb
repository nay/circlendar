require "rails_helper"

RSpec.describe "お知らせテンプレートの作成", type: :system do
  let(:admin) { create(:user, :admin) }

  it "件名と本文に差し込み文字を挿入して保存できる" do
    sign_in_with_form(admin)

    visit admin_announcement_templates_path
    click_link I18n.t("announcement_templates.index.new_announcement_template")

    fill_in I18n.t("announcement_templates.form.subject"), with: "お知らせ："
    find("option", text: "練習会ヘッドライン").select_option
    expect(page).to have_field(I18n.t("announcement_templates.form.subject"), with: "お知らせ：{{練習会ヘッドライン}}")

    fill_in I18n.t("announcement_templates.form.body"), with: "会場の案内です。"
    find("option", text: "会場案内").select_option
    expect(page).to have_field(I18n.t("announcement_templates.form.body"), with: "会場の案内です。{{会場案内}}")

    click_button I18n.t("helpers.submit.create")
    expect(page).to have_text(I18n.t("messages.create.success", model: AnnouncementTemplate.model_name.human))

    click_link "お知らせ：{{練習会ヘッドライン}}"
    expect(page).to have_text("会場の案内です。{{会場案内}}")
  end
end
