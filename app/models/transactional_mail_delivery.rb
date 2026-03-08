class TransactionalMailDelivery < MailDelivery
  enum :kind, { confirmation: "confirmation", password_reset: "password_reset" }

  validates :kind, presence: true
end
