class AnnouncementDelivery < MailDelivery
  belongs_to :announcement

  def request_send!(from:, subject:, body:, reply_to:)
    client = Rails.application.config.resend_client_class.constantize
    params = {
      from: from,
      to: [ address ],
      subject: subject,
      text: body,
      reply_to: reply_to
    }
    params[:scheduled_at] = scheduled_at.iso8601 if scheduled_at.present?

    response = client.send_email(params)
    update!(status: :requested, requested_at: Time.current, resend_id: response[:id])
  rescue StandardError => e
    update!(status: :failed, requested_at: Time.current, error_message: e.message)
  end
end
