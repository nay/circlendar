class AnnouncementMailer < ApplicationMailer
  def notify(announcement)
    @announcement = announcement
    @event = announcement.event

    mail(
      to: announcement.to_address,
      bcc: announcement.bcc_addresses,
      subject: announcement.subject
    )
  end
end
