class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{Setting.instance.circle_name} <#{ENV.fetch('MAILER_FROM', 'noreply@example.com')}>" }
  layout "mailer"
end
