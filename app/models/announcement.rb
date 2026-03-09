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

  def recipient_user_ids
    UserMailAddress.where(address: recipient_addresses).pluck(:user_id).uniq
  end

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
    pairs = addresses_with_deliveries
    all_addresses = pairs.map(&:first).uniq
    member_by_address = Member.joins(user: :mail_addresses)
                              .where(user_mail_addresses: { address: all_addresses })
                              .includes(user: :mail_addresses)
                              .flat_map { |m| m.user.mail_addresses.map { |ma| [ ma.address, m ] } }
                              .to_h
    pairs.map do |address, delivery|
      AnnouncementAddressDelivery.new(address: address, delivery: delivery, member: member_by_address[address])
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

  def addresses_with_deliveries
    loaded = deliveries.order(:id).to_a
    if loaded.any?
      loaded.flat_map { |d| d.addresses.map { |a| [ a, d ] } }
    else
      (recipient_addresses || []).map { |a| [ a, nil ] }
    end
  end
end
