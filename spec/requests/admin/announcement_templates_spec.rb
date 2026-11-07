require "rails_helper"

RSpec.describe "Admin::AnnouncementTemplates", type: :request do
  context "ログインしていない場合" do
    it "一覧を開くと、ログイン画面に移る" do
      get admin_announcement_templates_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "一覧を開くと、404を返す" do
      get admin_announcement_templates_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    before do
      sign_in(create(:user, :admin))
    end

    describe "GET /admin/announcement_templates" do
      before do
        create(:announcement_template, subject: "練習会のお知らせ")
      end

      it "テンプレートの一覧を表示する" do
        get admin_announcement_templates_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("練習会のお知らせ")
      end
    end

    describe "GET /admin/announcement_templates/:id" do
      let(:template) { create(:announcement_template, subject: "練習会のお知らせ") }

      it "テンプレートの詳細を表示する" do
        get admin_announcement_template_path(template)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("練習会のお知らせ")
      end
    end

    describe "GET /admin/announcement_templates/new" do
      it "新規作成の画面を表示する" do
        get new_admin_announcement_template_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/announcement_templates" do
      let(:params) { { announcement_template: { subject: "練習会のお知らせ", body: body } } }

      context "入力が正しい場合" do
        let(:body) { "{{練習会サマリー}}" }

        it "テンプレートを作成し、一覧に移る" do
          expect {
            post admin_announcement_templates_path, params: params
          }.to change(AnnouncementTemplate, :count).by(1)

          expect(response).to redirect_to(admin_announcement_templates_path)
        end
      end

      context "本文に無効な埋め込み情報がある場合" do
        let(:body) { "{{unknown}}" }

        it "テンプレートを作成せず、新規作成の画面を再表示する" do
          expect {
            post admin_announcement_templates_path, params: params
          }.not_to change(AnnouncementTemplate, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "GET /admin/announcement_templates/:id/edit" do
      let(:template) { create(:announcement_template) }

      it "編集画面を表示する" do
        get edit_admin_announcement_template_path(template)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/announcement_templates/:id" do
      let(:template) { create(:announcement_template, subject: "元の件名") }

      context "入力が正しい場合" do
        it "テンプレートを更新し、詳細画面に移る" do
          patch admin_announcement_template_path(template), params: { announcement_template: { subject: "新しい件名" } }

          expect(response).to redirect_to(admin_announcement_template_path(template))
          expect(template.reload.subject).to eq "新しい件名"
        end
      end

      context "既定のテンプレートにした場合" do
        let!(:default_template) { create(:announcement_template, default: true) }

        it "このテンプレートを既定にし、ほかのテンプレートを既定から外す" do
          patch admin_announcement_template_path(template), params: { announcement_template: { default: "1" } }

          expect(template.reload).to be_default
          expect(default_template.reload).not_to be_default
        end
      end

      context "件名が空の場合" do
        it "テンプレートを更新せず、編集画面を再表示する" do
          patch admin_announcement_template_path(template), params: { announcement_template: { subject: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(template.reload.subject).to eq "元の件名"
        end
      end
    end

    describe "DELETE /admin/announcement_templates/:id" do
      let!(:template) { create(:announcement_template) }

      it "テンプレートを削除し、一覧に移る" do
        expect {
          delete admin_announcement_template_path(template)
        }.to change(AnnouncementTemplate, :count).by(-1)

        expect(response).to redirect_to(admin_announcement_templates_path)
      end
    end
  end
end
