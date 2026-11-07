require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /" do
    context "ログインしていない場合" do
      it "ログイン画面に移る" do
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログインしている場合" do
      before do
        sign_in(create(:user))
      end

      context "公開済み・下書き・開催済みの練習会がある場合" do
        before do
          create(:event, status: :published, date: Date.current + 7, venue: create(:venue, short_name: "公開会場"))
          create(:event, status: :draft, date: Date.current + 7, venue: create(:venue, short_name: "下書き会場"))
          create(:event, status: :published, date: Date.current - 7, venue: create(:venue, short_name: "開催済み会場"))
        end

        it "公開済みでこれからの練習会だけを表示する" do
          get root_path

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("公開会場")
          expect(response.body).not_to include("下書き会場")
          expect(response.body).not_to include("開催済み会場")
        end
      end
    end
  end
end
