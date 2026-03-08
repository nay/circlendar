class MailDeliveryObserver
  MAILER_KIND_MAP = {
    "UserMailer" => "confirmation",
    "PasswordsMailer" => "password_reset"
  }.freeze

  def self.delivered_email(message)
    mailer_class = message["X-Mailer-Class"]&.value || message.delivery_handler&.name
    kind = MAILER_KIND_MAP[mailer_class]
    return unless kind

    Array(message.to).each do |address|
      MailDelivery::Transactional.create!(
        address: address,
        kind: kind,
        status: :requested,
        requested_at: Time.current
      )
    end
  rescue StandardError => e
    Rails.logger.error "[MailDeliveryObserver] Failed to record delivery: #{e.message}"
  end
end
