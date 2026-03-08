class TransactionalMailDelivery < MailDelivery
  KINDS = %w[confirmation password_reset].freeze

  validates :kind, presence: true, inclusion: { in: KINDS }
end
