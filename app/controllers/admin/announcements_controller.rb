class Admin::AnnouncementsController < ApplicationController
  before_action :set_announcement, only: %i[ show edit update destroy send_email ]

  def index
    @announcements = Announcement.includes(:event, :sender).order(created_at: :desc)
  end

  def show
  end

  def new
    @announcement = Announcement.new
    @announcement.event_id = params[:event_id] if params[:event_id]
    @events = Event.upcoming.order(:date)
    set_default_recipients
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.sender = Current.user

    if @announcement.save
      redirect_to [ :admin, @announcement ], notice: I18n.t("announcements.create.success")
    else
      @events = Event.upcoming.order(:date)
      set_default_recipients
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @events = Event.upcoming.order(:date)
    set_default_recipients
  end

  def update
    if @announcement.update(announcement_params)
      redirect_to [ :admin, @announcement ], notice: I18n.t("announcements.update.success")
    else
      @events = Event.upcoming.order(:date)
      set_default_recipients
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
    @announcement.update!(sent_at: Time.current)

    redirect_to [ :admin, @announcement ], notice: I18n.t("announcements.send_email.success")
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  def announcement_params
    params.require(:announcement).permit(:event_id, :subject, :body, :to_address, bcc_addresses: [])
  end

  def set_default_recipients
    @members = Member.includes(:user).where(users: { receives_announcements: true })
  end
end
