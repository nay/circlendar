require "rails_helper"

RSpec.describe "Admin::Venues", type: :request do
  context "ログインしていない場合" do
    it "一覧を開くと、ログイン画面に移る" do
      get admin_venues_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  context "一般メンバーとしてログインしている場合" do
    before do
      sign_in(create(:user))
    end

    it "一覧を開くと、404を返す" do
      get admin_venues_path
      expect(response).to have_http_status(:not_found)
    end
  end

  context "管理者としてログインしている場合" do
    before do
      sign_in(create(:user, :admin))
    end

    describe "GET /admin/venues" do
      before do
        create(:venue, name: "市民体育館")
      end

      it "会場の一覧を表示する" do
        get admin_venues_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("市民体育館")
      end
    end

    describe "GET /admin/venues/:id" do
      let(:venue) { create(:venue, name: "市民体育館") }

      it "会場の詳細を表示する" do
        get admin_venue_path(venue)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("市民体育館")
      end
    end

    describe "GET /admin/venues/new" do
      it "新規作成の画面を表示する" do
        get new_admin_venue_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/venues" do
      let(:params) do
        { venue: { name: name, short_name: "体育館", announcement_summary: "会場の概要", announcement_detail: "会場の詳細" } }
      end

      context "入力が正しい場合" do
        let(:name) { "市民体育館" }

        it "会場を作成し、詳細画面に移る" do
          expect {
            post admin_venues_path, params: params
          }.to change(Venue, :count).by(1)

          expect(response).to redirect_to(admin_venue_path(Venue.last))
        end
      end

      context "名前が空の場合" do
        let(:name) { "" }

        it "会場を作成せず、新規作成の画面を再表示する" do
          expect {
            post admin_venues_path, params: params
          }.not_to change(Venue, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "GET /admin/venues/:id/edit" do
      let(:venue) { create(:venue) }

      it "編集画面を表示する" do
        get edit_admin_venue_path(venue)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/venues/:id" do
      let(:venue) { create(:venue, name: "市民体育館") }

      context "入力が正しい場合" do
        it "会場を更新し、詳細画面に移る" do
          patch admin_venue_path(venue), params: { venue: { name: "県立体育館" } }

          expect(response).to redirect_to(admin_venue_path(venue))
          expect(venue.reload.name).to eq "県立体育館"
        end
      end

      context "名前が空の場合" do
        it "会場を更新せず、編集画面を再表示する" do
          patch admin_venue_path(venue), params: { venue: { name: "" } }

          expect(response).to have_http_status(:unprocessable_content)
          expect(venue.reload.name).to eq "市民体育館"
        end
      end
    end

    describe "DELETE /admin/venues/:id" do
      let!(:venue) { create(:venue) }

      context "練習会で使われていない場合" do
        it "会場を削除し、一覧に移る" do
          expect {
            delete admin_venue_path(venue)
          }.to change(Venue, :count).by(-1)

          expect(response).to redirect_to(admin_venues_path)
        end
      end

      context "練習会で使われている場合" do
        before do
          create(:event, venue: venue)
        end

        it "会場を削除せず、一覧に移ってエラーを表示する" do
          expect {
            delete admin_venue_path(venue)
          }.not_to change(Venue, :count)

          expect(response).to redirect_to(admin_venues_path)
          expect(flash[:alert]).to be_present
        end
      end
    end
  end
end
