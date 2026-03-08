class Admin::AnnouncementDeliveriesController < Admin::BaseController
  def process_queue
    AnnouncementDelivery.process_queue!
    head :ok
  end
end
