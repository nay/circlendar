class Current < ActiveSupport::CurrentAttributes
  attribute :session, :setting
  delegate :user, to: :session, allow_nil: true
end
