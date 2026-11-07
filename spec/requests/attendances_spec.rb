require "rails_helper"

RSpec.describe "Attendances", type: :request do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  describe "GET /events/:event_id/attendance/edit" do
    context "ログインしていない場合" do
      it "ログイン画面に移る" do
        get edit_event_attendance_path(event)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      context "ほかのメンバーが参加と回答している場合" do
        before do
          create(:attendance, event: event, status: :attending, player: create(:member, name: "参加するメンバー"))
        end

        it "出欠回答の画面に、参加者を表示する" do
          get edit_event_attendance_path(event)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include("参加するメンバー")
        end
      end
    end
  end

  describe "PATCH /events/:event_id/attendance" do
    let(:params) { { attendance: { status: "attending", after_party: "not_attending", message: "遅れて参加します" } } }

    context "ログインしていない場合" do
      it "出欠を記録せず、ログイン画面に移る" do
        expect {
          patch event_attendance_path(event), params: params
        }.not_to change(Attendance, :count)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "ログインしている場合" do
      before do
        sign_in(user)
      end

      context "まだ回答していない場合" do
        it "出欠を記録し、ダッシュボードに移る" do
          expect {
            patch event_attendance_path(event), params: params
          }.to change(Attendance, :count).by(1)

          expect(response).to redirect_to(root_path)
          expect(Attendance.last).to have_attributes(
            event: event, player: user.member, status: "attending", after_party: "not_attending", message: "遅れて参加します"
          )
        end
      end

      context "すでに回答している場合" do
        let!(:attendance) { create(:attendance, event: event, player: user.member, status: :not_attending) }

        it "記録済みの出欠を書き換え、ダッシュボードに移る" do
          expect {
            patch event_attendance_path(event), params: params
          }.not_to change(Attendance, :count)

          expect(response).to redirect_to(root_path)
          expect(attendance.reload).to have_attributes(status: "attending", after_party: "not_attending", message: "遅れて参加します")
        end
      end
    end
  end
end
