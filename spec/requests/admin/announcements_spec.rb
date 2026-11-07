require "rails_helper"

RSpec.describe "Admin::Announcements", type: :request do
  def recipient_checkbox(user)
    Nokogiri::HTML(response.body).at_css("input[name='announcement[recipient_user_ids][]'][value='#{user.id}']")
  end

  context "ログインしていない場合" do
    it "一覧を開くと、ログイン画面に移る" do
      get admin_announcements_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "一覧を開くと、404を返す" do
      get admin_announcements_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    let(:admin) { create(:user, :admin) }

    before do
      sign_in(admin)
    end

    describe "GET /admin/announcements" do
      before do
        create(:announcement, subject: "練習会のお知らせ")
      end

      it "お知らせの一覧を表示する" do
        get admin_announcements_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("練習会のお知らせ")
      end
    end

    describe "GET /admin/announcements/:id" do
      let(:announcement) { create(:announcement, subject: "練習会のお知らせ") }

      it "お知らせの詳細を表示する" do
        get admin_announcement_path(announcement)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("練習会のお知らせ")
      end
    end

    describe "GET /admin/announcements/new" do
      it "すべてのメンバーを宛先に選んだ、新規作成の画面を表示する" do
        get new_admin_announcement_path

        expect(response).to have_http_status(:ok)
        expect(recipient_checkbox(admin)["checked"]).to be_present
      end
    end

    describe "POST /admin/announcements" do
      let(:member) { create(:user, email_address: "member@example.com") }
      let(:params) do
        { announcement: { subject: subject, body: "本文", recipient_user_ids: [ "", member.id.to_s ] } }
      end

      context "入力が正しい場合" do
        let(:subject) { "練習会のお知らせ" }

        it "選んだメンバーのアドレスを宛先にしてお知らせを作成し、詳細画面に移る" do
          expect {
            post admin_announcements_path, params: params
          }.to change(Announcement, :count).by(1)

          announcement = Announcement.last
          expect(response).to redirect_to(admin_announcement_path(announcement))
          expect(announcement.recipient_addresses).to eq [ "member@example.com" ]
        end
      end

      context "件名が空の場合" do
        let(:subject) { "" }

        it "お知らせを作成せず、新規作成の画面を再表示する" do
          expect {
            post admin_announcements_path, params: params
          }.not_to change(Announcement, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "POST /admin/announcements（テンプレートの適用）" do
      let(:event) { create(:event, date: Date.current + 7, venue: create(:venue, short_name: "体育館")) }
      let(:template) { create(:announcement_template, subject: "{{練習会ヘッドライン}}のお知らせ", body: body) }
      let(:body) { "{{練習会サマリー}}" }
      let(:params) do
        { submit_type: "apply_template", announcement: { announcement_template_id: template_id, event_ids: event_ids, subject: "", body: "" } }
      end
      let(:template_id) { template.id }
      let(:event_ids) { [ "", event.id.to_s ] }

      context "テンプレートと練習会を選んでいる場合" do
        it "お知らせを作成せず、練習会の情報を埋め込んだ件名で新規作成の画面を再表示する" do
          expect {
            post admin_announcements_path, params: params
          }.not_to change(Announcement, :count)

          expect(response.body).to include("#{event.headline}のお知らせ")
        end
      end

      context "テンプレートを選んでいない場合" do
        let(:template_id) { "" }

        it "埋め込みをせず、テンプレートを選ぶよう促す" do
          post admin_announcements_path, params: params

          expect(flash[:alert]).to eq I18n.t("announcements.apply_template.template_required")
        end
      end

      context "練習会の情報を埋め込むテンプレートで、練習会を選んでいない場合" do
        let(:event_ids) { [ "" ] }

        it "埋め込みをせず、練習会を選ぶよう促す" do
          post admin_announcements_path, params: params

          expect(flash[:alert]).to eq I18n.t("announcements.apply_template.event_required")
        end
      end

      context "サインアップURLを埋め込むテンプレートで、サインアップトークンが未発行の場合" do
        let(:body) { "{{サインアップURL}}" }

        it "埋め込みをせず、サインアップトークンの発行を促す" do
          post admin_announcements_path, params: params

          expect(flash[:alert]).to eq I18n.t("announcements.apply_template.signup_token_required")
        end
      end
    end

    describe "GET /admin/announcements/:id/edit" do
      let!(:member) { create(:user) }

      context "宛先にメンバーを選んで保存していた場合" do
        let(:announcement) { create(:announcement, recipient_addresses: [ member.email_address ]) }

        it "そのメンバーを選んだ編集画面を表示する" do
          get edit_admin_announcement_path(announcement)

          expect(response).to have_http_status(:ok)
          expect(recipient_checkbox(member)["checked"]).to be_present
        end
      end

      context "宛先を1人も選ばずに保存していた場合" do
        let(:announcement) { create(:announcement, recipient_addresses: []) }

        it "だれも選んでいない編集画面を表示する" do
          get edit_admin_announcement_path(announcement)

          expect(response).to have_http_status(:ok)
          expect(recipient_checkbox(member)["checked"]).to be_nil
        end
      end
    end

    describe "PATCH /admin/announcements/:id" do
      let(:member) { create(:user, email_address: "member@example.com") }
      let(:announcement) { create(:announcement, subject: "元の件名", recipient_addresses: [ "member@example.com" ]) }

      context "入力が正しい場合" do
        it "お知らせを更新し、詳細画面に移る" do
          patch admin_announcement_path(announcement), params: { announcement: { subject: "新しい件名" } }

          expect(response).to redirect_to(admin_announcement_path(announcement))
          expect(announcement.reload.subject).to eq "新しい件名"
        end
      end

      context "宛先をすべて外した場合" do
        it "宛先を空にして保存する" do
          patch admin_announcement_path(announcement), params: { announcement: { recipient_user_ids: [ "" ] } }

          expect(response).to redirect_to(admin_announcement_path(announcement))
          expect(announcement.reload.recipient_addresses).to eq []
        end
      end

      context "件名が空の場合" do
        it "お知らせを更新せず、編集画面を再表示する" do
          patch admin_announcement_path(announcement), params: { announcement: { subject: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(announcement.reload.subject).to eq "元の件名"
        end
      end
    end

    describe "DELETE /admin/announcements/:id" do
      let!(:announcement) { create(:announcement) }

      it "お知らせを削除し、一覧に移る" do
        expect {
          delete admin_announcement_path(announcement)
        }.to change(Announcement, :count).by(-1)

        expect(response).to redirect_to(admin_announcements_path)
      end
    end

    describe "POST /admin/announcements/:id/send_email" do
      context "まだ送信していない場合" do
        context "宛先がある場合" do
          let(:announcement) { create(:announcement, recipient_addresses: [ "member@example.com" ]) }

          it "宛先に送信し、送信した管理者を記録して、詳細画面に移る" do
            post send_email_admin_announcement_path(announcement)

            expect(response).to redirect_to(admin_announcement_path(announcement))
            announcement.reload
            expect(announcement.delivery_started_at).to be_present
            expect(announcement.sender).to eq admin
            expect(announcement.deliveries.sole).to have_attributes(status: "requested", addresses: [ "member@example.com" ])
          end
        end

        context "宛先がない場合" do
          let(:announcement) { create(:announcement, recipient_addresses: []) }

          it "送信せず、詳細画面に戻ってエラーを表示する" do
            post send_email_admin_announcement_path(announcement)

            expect(response).to redirect_to(admin_announcement_path(announcement))
            expect(flash[:alert]).to eq I18n.t("announcements.send_email.no_recipients")
            expect(announcement.reload.deliveries).to be_empty
          end
        end
      end

      context "すでに送信を始めている場合" do
        let(:announcement) { create(:announcement, recipient_addresses: [ "member@example.com" ], delivery_started_at: 1.hour.ago) }

        it "もう一度は送信せず、詳細画面に戻ってエラーを表示する" do
          post send_email_admin_announcement_path(announcement)

          expect(response).to redirect_to(admin_announcement_path(announcement))
          expect(flash[:alert]).to eq I18n.t("announcements.send_email.delivery_already_started")
          expect(announcement.reload.deliveries).to be_empty
        end
      end
    end

    describe "GET /admin/announcements/:id/deliveries" do
      let(:announcement) { create(:announcement) }

      before do
        create(:announcement_delivery, announcement: announcement, addresses: [ "member@example.com" ])
      end

      it "送信履歴を表示する" do
        get deliveries_admin_announcement_path(announcement)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("member@example.com")
      end
    end

    describe "GET /admin/announcements/pending_deliveries" do
      before do
        create(:announcement_delivery, announcement: create(:announcement, subject: "すぐ送るお知らせ"))
        create(:announcement_delivery, announcement: create(:announcement, subject: "あとで送るお知らせ"), next_run_at: 1.hour.from_now)
      end

      it "送信待ちのお知らせを表示する" do
        get pending_deliveries_admin_announcements_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("すぐ送るお知らせ")
        expect(response.body).to include("あとで送るお知らせ")
      end
    end

    describe "POST /admin/announcements/process_queue" do
      let!(:delivery) { create(:announcement_delivery) }

      it "送信待ちのものを送信し、送信待ちの画面に移る" do
        post process_queue_admin_announcements_path

        expect(response).to redirect_to(pending_deliveries_admin_announcements_path)
        expect(delivery.reload).to be_requested
      end
    end
  end
end
