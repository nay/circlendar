class AnnouncementAddressDelivery
  attr_reader :address, :user_mail_address, :status, :requested_at, :next_run_at, :error_message, :delivery_result

  def initialize(address:, user_mail_address: nil, delivery: nil, delivery_result: nil)
    @address = address
    @user_mail_address = user_mail_address
    @delivery_result = delivery_result
    return unless delivery

    @status = delivery.failed_addresses.include?(address) ? "failed" : delivery.status
    @requested_at = delivery.requested_at
    @next_run_at = delivery.next_run_at
    @error_message = delivery.error_message if failed?
  end

  def user
    user_mail_address&.user
  end

  def delivery_status
    return nil unless status
    return "failed" if failed?

    if delivery_result && !delivery_result.requested?
      return delivery_result.event
    end

    status
  end

  def failed?
    status == "failed"
  end
end
