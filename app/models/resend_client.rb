class ResendClient
  def self.send_email(params)
    Resend::Emails.send(params)
  end
end
