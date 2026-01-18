class AnnouncementMailer < ApplicationMailer
  def notify(announcement)
    @announcement = announcement
    @events = announcement.events

    mail(
      to: announcement.to_address,
      bcc: announcement.bcc_addresses,
      subject: announcement.subject
    )
  end
end
