class ResendClient
  def self.send_email(params)
    Resend::Emails.send(params)
  end

  def self.send_batch(params_array)
    Resend::Batch.send(params_array)
  end
end
