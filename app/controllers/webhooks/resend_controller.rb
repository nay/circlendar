class Webhooks::ResendController < ApplicationController
  skip_forgery_protection
  allow_unauthenticated_access

  def create
    verify_signature!
    process_event
    head :ok
  rescue Svix::WebhookVerificationError => e
    Rails.logger.warn "[Webhooks::Resend] Signature verification failed: #{e.message}"
    head :unauthorized
  rescue StandardError => e
    Rails.logger.error "[Webhooks::Resend] #{e.class}: #{e.message}"
    head :internal_server_error
  end

  private

  def verify_signature!
    secret = ENV["RESEND_WEBHOOK_SIGNING_SECRET"]
    if secret.blank?
      raise "RESEND_WEBHOOK_SIGNING_SECRET is not configured" if Rails.env.production?
      return
    end

    wh = Svix::Webhook.new(secret)
    wh.verify(request.raw_post, {
      "svix-id" => request.headers["svix-id"],
      "svix-timestamp" => request.headers["svix-timestamp"],
      "svix-signature" => request.headers["svix-signature"]
    })
  end

  def process_event
    event = params[:type]&.delete_prefix("email.")
    return unless AnnouncementDeliveryResult::RESEND_EVENTS.include?(event&.to_sym)

    email_id = params.dig(:data, :email_id)
    return unless email_id.present?

    result = AnnouncementDeliveryResult.find_by(resend_id: email_id)
    return unless result
    return if result.bounced? || result.complained?

    result.update!(event: event)
  end
end
