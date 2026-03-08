class Announcement < ApplicationRecord
  has_many :event_announcements, dependent: :destroy
  has_many :events, through: :event_announcements
  has_many :deliveries, class_name: "AnnouncementDelivery", dependent: :destroy

  belongs_to :template, class_name: "AnnouncementTemplate", foreign_key: "announcement_template_id", optional: true
  belongs_to :sender, class_name: "User", foreign_key: "sent_by", optional: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :unsent, -> { where(sent_at: nil) }

  validates :subject, presence: true
  validates :body, presence: true

  def recipient_user_ids=(user_ids)
    self.recipient_addresses = UserMailAddress.where(user_id: user_ids).pluck(:address)
  end

  def sent?
    sent_at.present?
  end

  def apply_template
    return unless template

    self.subject = AnnouncementTemplate.fill_placeholders(template.subject, events)
    self.body = AnnouncementTemplate.fill_placeholders(template.body, events)
  end

  def address_deliveries
    loaded = deliveries.order(:id).to_a
    all_addresses = loaded.flat_map(&:addresses).uniq
    member_by_address = build_member_by_address(all_addresses)

    loaded.flat_map do |delivery|
      delivery.addresses.map do |address|
        AnnouncementAddressDelivery.new(delivery: delivery, address: address, member: member_by_address[address])
      end
    end
  end

  def create_deliveries!
    ordered_addresses = UserMailAddress.where(address: recipient_addresses)
                                      .joins(:user).merge(User.ordered)
                                      .pluck(:address)
    ordered_addresses += recipient_addresses - ordered_addresses

    deliveries.create!(addresses: ordered_addresses)
  end

  private

  def build_member_by_address(addresses)
    members = Member.joins(user: :mail_addresses)
                    .where(user_mail_addresses: { address: addresses })
                    .includes(user: :mail_addresses)
    result = {}
    members.each do |member|
      member.user.mail_addresses.each { |ma| result[ma.address] = member }
    end
    result
  end
end
