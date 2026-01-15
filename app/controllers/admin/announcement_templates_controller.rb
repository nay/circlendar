class Admin::AnnouncementTemplatesController < Admin::BaseController
  def index
    @announcement_templates = AnnouncementTemplate.order(:subject)
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

  private

  def announcement_template_params
    params.require(:announcement_template).permit(:subject, :body, :default)
  end
end
