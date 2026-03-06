require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  let(:admin_user) do
    User.create!(
      email_address: "admin@example.com",
      password: "password123",
      role: "admin",
      confirmed_at: Time.current
    )
  end

  let!(:admin_member) do
    Member.create!(name: "管理者", user: admin_user)
  end

  let(:venue) do
    Venue.create!(
      name: "テスト会場",
      short_name: "テスト",
      announcement_summary: "テスト会場の概要",
      announcement_detail: "テスト会場の詳細"
    )
  end

  let(:event) do
    Event.create!(venue: venue, date: Date.today, schedule: "10:00-12:00", status: :published)
  end

  before do
    post session_path, params: { email_address: admin_user.email_address, password: "password123" }
  end

  describe "GET /admin/events/:id" do
    it "200を返す" do
      get admin_event_path(event)
      expect(response).to have_http_status(:ok)
    end

    context "出欠回答がある場合" do
      let(:attending_user) do
        User.create!(
          email_address: "member@example.com",
          password: "password123",
          role: "member",
          confirmed_at: Time.current
        )
      end

      let!(:attending_member) do
        Member.create!(name: "メンバー1", user: attending_user)
      end

      before do
        Attendance.create!(event: event, player: attending_member, status: :attending)
      end

      it "200を返す" do
        get admin_event_path(event)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
