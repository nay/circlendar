Resend.api_key = ENV["RESEND_API_KEY"]

Rails.application.config.resend_client_class = if Rails.env.production?
  "ResendClient"
else
  "FakeResendClient"
end
