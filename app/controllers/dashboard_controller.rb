class DashboardController < ApplicationController
  def index
    # 公開済みかつ未開催の練習会（日付の早い順）
    upcoming_events = Event.published.upcoming.includes(:venue, :attendances).order(date: :asc)

    # 自分の出席状況別に分類
    @attending_events = []
    @undecided_events = []
    @not_attending_events = []

    upcoming_events.each do |event|
      attendance = event.attendances.find { |a| a.player_id == current_member.id }

      if attendance
        case attendance.status
        when "attending"
          @attending_events << { event: event, attendance: attendance }
        when "not_attending"
          @not_attending_events << { event: event, attendance: attendance }
        else # undecided
          @undecided_events << { event: event, attendance: attendance }
        end
      else
        # 未回答の場合は未定扱い
        @undecided_events << { event: event, attendance: nil }
      end
    end
  end
end
