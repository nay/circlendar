class AttendancesController < ApplicationController
  before_action :set_event

  def edit
    @attendance = @event.attendances.find_or_initialize_by(player: current_member)
    # 練習またはアフターに参加する人を取得
    @attendees = @event.attendances
                       .where("status = ? OR after_party = ?", "attending", "attending")
                       .includes(:player)
  end

  def update
    @attendance = @event.attendances.find_or_initialize_by(player: current_member)
    @attendance.assign_attributes(attendance_params)

    if @attendance.save
      redirect_to dashboard_path, notice: I18n.t("messages.update.success", model: Attendance.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def attendance_params
    params.require(:attendance).permit(:status, :after_party, :message)
  end
end
