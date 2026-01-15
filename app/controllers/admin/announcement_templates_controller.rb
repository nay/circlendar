class Admin::AnnouncementTemplatesController < Admin::BaseController
  def index
    @announcement_templates = AnnouncementTemplate.order(:name)
  end
end
