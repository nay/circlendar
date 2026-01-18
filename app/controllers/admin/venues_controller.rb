class Admin::VenuesController < Admin::BaseController
  before_action :set_venue, only: %i[ show edit update destroy ]

  def index
    @venues = Venue.order(:name)
  end

  def show
  end

  def new
    @venue = Venue.new
  end

  def create
    @venue = Venue.new(venue_params)

    if @venue.save
      redirect_to [ :admin, @venue ], notice: I18n.t("venues.create.success", model: Venue.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @venue.update(venue_params)
      redirect_to [ :admin, @venue ], notice: I18n.t("venues.update.success", model: Venue.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @venue.destroy
      redirect_to admin_venues_path, notice: I18n.t("venues.destroy.success", model: Venue.model_name.human)
    else
      redirect_to admin_venues_path, alert: @venue.errors.full_messages.join(", ")
    end
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  end

  def venue_params
    params.require(:venue).permit(:name, :url, :announcement_summary, :announcement_detail)
  end
end
