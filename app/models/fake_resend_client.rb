class FakeResendClient
  def self.send_email(params)
    Rails.logger.info "[FakeResendClient] #{params[:to]} | subject: #{params[:subject]} | scheduled_at: #{params[:scheduled_at]}"
    { id: "fake_#{SecureRandom.uuid}" }
  end

  def self.send_batch(params_array)
    params_array.each do |params|
      Rails.logger.info "[FakeResendClient] batch #{params[:to]} | subject: #{params[:subject]}"
    end
    { data: params_array.map { { id: "fake_#{SecureRandom.uuid}" } } }
  end
end
