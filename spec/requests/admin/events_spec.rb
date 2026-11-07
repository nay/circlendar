require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  context "ログインしていない場合" do
    it "一覧を開くと、ログイン画面に移る" do
      get admin_events_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "一覧を開くと、404を返す" do
      get admin_events_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    before do
      sign_in(create(:user, :admin))
    end

    describe "GET /admin/events" do
      before do
        create(:event, date: Date.current + 7, venue: create(:venue, short_name: "開催待ち会場"))
        create(:event, date: Date.current - 7, venue: create(:venue, short_name: "終了会場"))
      end

      context "開催待ちのタブを開いた場合" do
        it "これからの練習会だけを表示する" do
          get admin_events_path(tab: "upcoming")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("開催待ち会場")
          expect(response.body).not_to include("終了会場")
        end
      end

      context "終了のタブを開いた場合" do
        it "開催済みの練習会だけを表示する" do
          get admin_events_path(tab: "past")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("終了会場")
          expect(response.body).not_to include("開催待ち会場")
        end
      end
    end

    describe "GET /admin/events/:id" do
      let(:event) { create(:event, status: :published) }

      context "お知らせのタブを開いた場合" do
        before do
          create(:announcement, subject: "練習会のお知らせ", events: [ event ])
        end

        it "この練習会のお知らせを表示する" do
          get admin_event_path(event, tab: "announcements")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("練習会のお知らせ")
        end
      end

      context "参加者のタブを開いた場合" do
        before do
          create(:attendance, event: event, status: :attending, player: create(:member, name: "参加するメンバー"))
        end

        it "参加と回答したメンバーを表示する" do
          get admin_event_path(event, tab: "attending")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("参加するメンバー")
        end
      end

      context "不参加・保留の回答者のタブを開いた場合" do
        before do
          create(:attendance, event: event, status: :not_attending, player: create(:member, name: "不参加のメンバー"))
        end

        it "不参加と回答したメンバーを表示する" do
          get admin_event_path(event, tab: "not_attending")

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("不参加のメンバー")
        end
      end
    end

    describe "GET /admin/events/new" do
      context "コピー元の練習会を指定しない場合" do
        it "新規作成の画面を表示する" do
          get new_admin_event_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "コピー元の練習会を指定した場合" do
        let(:source_event) { create(:event, schedule: "18:30-21:30") }

        it "コピー元の時間帯を入れた、新規作成の画面を表示する" do
          get new_admin_event_path(source_event_id: source_event.id)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("18:30-21:30")
        end
      end
    end

    describe "POST /admin/events" do
      let(:venue) { create(:venue) }
      let(:params) { { event: { venue_id: venue.id, date: Date.current + 7, schedule: schedule, status: "draft" } } }

      context "入力が正しい場合" do
        let(:schedule) { "10:00-12:00" }

        it "練習会を作成し、詳細画面に移る" do
          expect {
            post admin_events_path, params: params
          }.to change(Event, :count).by(1)

          expect(response).to redirect_to(admin_event_path(Event.last))
        end
      end

      context "時間帯が空の場合" do
        let(:schedule) { "" }

        it "練習会を作成せず、新規作成の画面を再表示する" do
          expect {
            post admin_events_path, params: params
          }.not_to change(Event, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "GET /admin/events/:id/edit" do
      let(:event) { create(:event) }

      it "編集画面を表示する" do
        get edit_admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/events/:id" do
      let(:event) { create(:event, schedule: "10:00-12:00") }

      context "入力が正しい場合" do
        it "練習会を更新し、詳細画面に移る" do
          patch admin_event_path(event), params: { event: { schedule: "13:00-17:00" } }

          expect(response).to redirect_to(admin_event_path(event))
          expect(event.reload.schedule).to eq "13:00-17:00"
        end
      end

      context "時間帯が空の場合" do
        it "練習会を更新せず、編集画面を再表示する" do
          patch admin_event_path(event), params: { event: { schedule: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(event.reload.schedule).to eq "10:00-12:00"
        end
      end
    end

    describe "DELETE /admin/events/:id" do
      let!(:event) { create(:event) }

      it "練習会を削除し、一覧に移る" do
        expect {
          delete admin_event_path(event)
        }.to change(Event, :count).by(-1)

        expect(response).to redirect_to(admin_events_path)
      end
    end
  end
end
