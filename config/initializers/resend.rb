Resend.api_key = ENV["RESEND_API_KEY"]

Rails.application.config.resend_client = if Rails.env.production?
  ResendClient
else
  FakeResendClient
end
