class DashboardController < ApplicationController
  def index
    # 自分の出席情報を先に取得してインデックス化（現在日以降すべて）
    my_attendances = current_member.attendances
                                   .joins(:event)
                                   .where('events.date >= ?', Date.current)
                                   .index_by(&:event_id)

    # 公開済みかつ未開催の練習会（日付の早い順）
    upcoming_events = Event.published.upcoming.includes(:venue).order(date: :asc)

    # 月ごとにグループ化
    @events_by_month = upcoming_events.group_by { |event| event.date.beginning_of_month }.map do |month, events|
      {
        month: month,
        events: events.map { |event| { event: event, attendance: my_attendances[event.id] } }
      }
    end

    # カレンダー用: 今月から2ヶ月分の範囲
    start_date = Date.current.beginning_of_month
    end_date = (start_date + 1.month).end_of_month

    # 期間内の全イベント（公開済み）を取得
    calendar_events = Event.published
                           .where(date: start_date..end_date)
                           .index_by(&:date)

    # 日付ごとのデータを準備
    @calendar_days = (start_date..end_date).map do |date|
      event = calendar_events[date]
      attendance = event ? my_attendances[event.id] : nil

      {
        date: date,
        event: event,
        attendance: attendance
      }
    end
  end
end
