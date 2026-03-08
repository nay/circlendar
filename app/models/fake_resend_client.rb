class FakeResendClient
  def self.send_email(params)
    Rails.logger.info "[FakeResendClient] #{params[:to]} | subject: #{params[:subject]} | scheduled_at: #{params[:scheduled_at]}"
    { id: "fake_#{SecureRandom.uuid}" }
  end
end
