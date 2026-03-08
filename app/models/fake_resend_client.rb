class FakeResendClient
  def self.send_batch(params_array)
    params_array.each do |params|
      Rails.logger.info "[FakeResendClient] batch #{params[:to]} | subject: #{params[:subject]}"
    end
    {
      data: params_array.map { { id: "fake_#{SecureRandom.uuid}" } },
      headers: { "x-resend-daily-quota" => "0" }
    }
  end
end
