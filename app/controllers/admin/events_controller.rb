class Admin::EventsController < Admin::BaseController
  before_action :set_event, only: %i[ show edit update destroy ]

  def index
    @current_tab = params[:tab] || "upcoming"
    base_scope = Event.includes(:venue)

    @events = case @current_tab
    when "past"
      base_scope.past.order(date: :desc)
    else
      base_scope.upcoming.order(date: :desc)
    end
  end

  def show
    @attendances = @event.attendances.includes(:player).order("players.name")
    @announcements = @event.announcements.order(created_at: :desc)
  end

  def new
    @event = Event.new
    @venues = Venue.all
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to [ :admin, @event ], notice: I18n.t("events.create.success")
    else
      @venues = Venue.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @venues = Venue.all
  end

  def update
    if @event.update(event_params)
      redirect_to [ :admin, @event ], notice: I18n.t("events.update.success")
    else
      @venues = Venue.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to admin_events_path, notice: I18n.t("events.destroy.success")
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:venue_id, :date, :start_time, :end_time, :notes, :status)
    end
end
