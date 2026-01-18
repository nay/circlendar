class AttendancesController < ApplicationController
  before_action :set_event

  def edit
    @attendance = @event.attendances.find_or_initialize_by(player: current_member)
    @attendees = @event.attendances.attending.includes(:player)
  end

  def update
    @attendance = @event.attendances.find_or_initialize_by(player: current_member)
    @attendance.assign_attributes(attendance_params)

    if @attendance.save
      redirect_to dashboard_path, notice: "出席情報を更新しました。"
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
