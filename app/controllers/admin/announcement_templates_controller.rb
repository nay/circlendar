class Admin::AnnouncementTemplatesController < Admin::BaseController
  before_action :set_announcement_template, only: %i[show edit update destroy]

  def index
    @announcement_templates = AnnouncementTemplate.order(:subject)
  end

  def show
  end

  def new
    @announcement_template = AnnouncementTemplate.new
  end

  def create
    @announcement_template = AnnouncementTemplate.new(announcement_template_params)

    if @announcement_template.save
      redirect_to admin_announcement_templates_path, notice: t("announcement_templates.create.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @announcement_template.update(announcement_template_params)
      redirect_to admin_announcement_template_path(@announcement_template), notice: t("announcement_templates.update.success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement_template.destroy
    redirect_to admin_announcement_templates_path, notice: t("announcement_templates.destroy.success")
  end

  private

  def set_announcement_template
    @announcement_template = AnnouncementTemplate.find(params[:id])
  end

  def announcement_template_params
    params.require(:announcement_template).permit(:subject, :body, :default)
  end
end
