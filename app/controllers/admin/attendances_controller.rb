class Admin::AttendancesController < Admin::BaseController
  before_action :set_event

  def index
    @attendances = @event.attendances.includes(:player).order("players.name")
    @all_members = Member.order(:name)
  end

  def create
    @attendance = @event.attendances.build(attendance_params)

    if @attendance.save
      redirect_to admin_event_attendances_path(@event), notice: "出席情報を登録しました。"
    else
      @attendances = @event.attendances.includes(:player).order("players.name")
      @all_members = Member.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @attendance = @event.attendances.find(params[:id])

    if @attendance.update(attendance_params)
      redirect_to admin_event_attendances_path(@event), notice: "出席情報を更新しました。"
    else
      @attendances = @event.attendances.includes(:player).order("players.name")
      @all_members = Member.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def attendance_params
    params.require(:attendance).permit(:player_id, :status, :arrival_time, :departure_time, :after_party, :message)
  end
end
