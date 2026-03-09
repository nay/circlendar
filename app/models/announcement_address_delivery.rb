class AnnouncementAddressDelivery
  attr_reader :address, :member, :status, :requested_at, :next_run_at, :error_message

  def initialize(address:, member: nil, delivery: nil)
    @address = address
    @member = member
    return unless delivery

    @status = delivery.failed_addresses.include?(address) ? "failed" : delivery.status
    @requested_at = delivery.requested_at
    @next_run_at = delivery.next_run_at
    @error_message = delivery.error_message if failed?
  end

  def failed?
    status == "failed"
  end
end
