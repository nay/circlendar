class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :mail_addresses, class_name: "UserMailAddress", dependent: :destroy, autosave: true
  accepts_nested_attributes_for :mail_addresses, allow_destroy: true, reject_if: ->(attrs) { attrs[:address].blank? && attrs[:id].blank? }
  has_one :member, dependent: :destroy, autosave: true

  delegate :name, :name=, :organization_name, :organization_name=,
           :rank, :rank=, :description, :description=, :formatted_rank,
           to: :member, allow_nil: true

  enum :role, { admin: "admin", member: "member" }

  scope :active, -> { where(disabled_at: nil) }
  scope :receives_announcements, -> { where(receives_announcements: true) }
  scope :ordered, -> {
    order(
      Arel.sql("CASE users.role WHEN 'admin' THEN 0 ELSE 1 END"),
      Arel.sql("users.last_accessed_at DESC NULLS LAST"),
      Arel.sql("users.created_at DESC")
    )
  }

  before_validation :mark_blank_mail_addresses_for_destruction
  validate :validate_mail_addresses_count
  after_validation :promote_mail_address_errors

  # -- バーチャルアクセサ（mail_addresses.first への委譲） --

  def email_address
    mail_addresses.first&.address
  end

  def email_address=(value)
    if (existing = mail_addresses.first)
      existing.address = value
    else
      mail_addresses.build(address: value)
    end
  end

  def confirmation_token
    mail_addresses.first&.confirmation_token
  end

  def confirmed_at
    mail_addresses.first&.confirmed_at
  end

  def confirmed_at=(value)
    if (existing = mail_addresses.first)
      existing.confirmed_at = value
    else
      mail_addresses.build(confirmed_at: value)
    end
  end

  # -- 状態確認・操作 --

  def confirmed?
    mail_addresses.any?(&:confirmed?)
  end

  def disabled?
    disabled_at.present?
  end

  def generate_confirmation_token!
    mail_addresses.first&.generate_confirmation_token!
  end

  def confirm!
    mail_addresses.first&.confirm!
  end

  def confirm_new_mail_addresses
    mail_addresses.each do |ma|
      ma.confirmed_at = Time.current if ma.new_record? && !ma.marked_for_destruction?
    end
  end

  private

  def mark_blank_mail_addresses_for_destruction
    mail_addresses.each do |ma|
      ma.mark_for_destruction if ma.persisted? && ma.address.blank?
    end
  end

  def validate_mail_addresses_count
    if mail_addresses.reject(&:marked_for_destruction?).empty?
      errors.add(:base, "メールアドレスは1件以上必要です")
    end
  end

  def promote_mail_address_errors
    mail_addresses.each do |ma|
      next if ma.valid?

      ma.errors.where(:address).each do |error|
        errors.add(:email_address, error.type, **error.options) unless errors.where(:email_address, error.type).any?
      end
    end
  end
end
