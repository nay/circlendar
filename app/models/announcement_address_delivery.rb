class AnnouncementAddressDelivery
  attr_reader :address, :member, :status, :requested_at, :next_run_at, :error_message

  def initialize(delivery:, address:, member: nil)
    @address = address
    @member = member
    failed = delivery.failed_addresses.include?(address)
    @status = failed ? "failed" : delivery.status
    @requested_at = delivery.requested_at
    @next_run_at = delivery.next_run_at
    @error_message = delivery.error_message if failed || delivery.failed?
  end
end
