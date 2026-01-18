class Admin::AnnouncementsController < Admin::BaseController
  before_action :set_announcement, only: %i[ show edit update destroy send_email ]
  before_action :set_event, only: %i[ new create show edit update ]

  def index
    @announcements = Announcement.includes(:events, :sender).order(created_at: :desc)
  end

  def show
  end

  def new
    @announcement = Announcement.new
    @announcement.events << @event if @event
    prepare_form_data
  end

  def create
    @announcement = Announcement.new(announcement_params)

    if params[:submit_type] == "apply_template"
      apply_template
      render :new, status: :unprocessable_entity and return
    end

    if @announcement.save
      redirect_to admin_announcement_path(@announcement, @event ? { event_id: @event.id } : {}), notice: I18n.t("announcements.create.success")
    else
      prepare_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    prepare_form_data
  end

  def update
    @announcement.assign_attributes(announcement_params)

    if params[:submit_type] == "apply_template"
      apply_template
      render :edit, status: :unprocessable_entity and return
    end

    if @announcement.save
      redirect_to admin_announcement_path(@announcement, @event ? { event_id: @event.id } : {}), notice: I18n.t("announcements.update.success")
    else
      prepare_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    redirect_to admin_announcements_path, notice: I18n.t("announcements.destroy.success")
  end

  def send_email
    if @announcement.sent?
      redirect_to [ :admin, @announcement ], alert: I18n.t("announcements.send_email.already_sent")
      return
    end

    AnnouncementMailer.notify(@announcement).deliver_now
    @announcement.update!(sent_at: Time.current, sender: Current.user)

    redirect_to [ :admin, @announcement ], notice: I18n.t("announcements.send_email.success")
  end

  private

  def prepare_form_data
    @events = Event.upcoming.order(:date)
    @announcement_templates = AnnouncementTemplate.order(:subject)
    @members = Member.includes(:user).where(users: { receives_announcements: true })
  end

  def apply_template
    prepare_form_data

    unless @announcement.template
      flash.now[:alert] = I18n.t("announcements.apply_template.template_required")
      return
    end

    if @announcement.template.has_placeholders? && @announcement.events.empty?
      flash.now[:alert] = I18n.t("announcements.apply_template.event_required")
      return
    end

    @announcement.apply_template
  end

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:event_id]) if params[:event_id]
  end

  def announcement_params
    params.require(:announcement).permit(:announcement_template_id, :subject, :body, :to_address, bcc_addresses: [], event_ids: [])
  end
end
