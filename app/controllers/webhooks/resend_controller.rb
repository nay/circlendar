class Webhooks::ResendController < ApplicationController
  skip_forgery_protection
  allow_unauthenticated_access

  def create
    verify_signature!
    process_event
    head :ok
  rescue StandardError => e
    Rails.logger.error "[Webhooks::Resend] #{e.class}: #{e.message}"
    head :ok
  end

  private

  def verify_signature!
    secret = ENV["RESEND_WEBHOOK_SIGNING_SECRET"]
    return if secret.blank?

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
    address = Array(params.dig(:data, :to)).first

    result = AnnouncementDeliveryResult.find_or_initialize_by(resend_id: email_id)
    if result.new_record?
      delivery = AnnouncementDelivery.where("resend_ids::jsonb @> ?", [ email_id ].to_json).first
      return unless delivery

      result.announcement_delivery = delivery
      result.address = address || find_address_by_resend_id(delivery, email_id)
    end
    result.update!(event: event)
  end

  def find_address_by_resend_id(delivery, resend_id)
    index = delivery.resend_ids&.index(resend_id)
    index ? delivery.addresses[index] : nil
  end
end
