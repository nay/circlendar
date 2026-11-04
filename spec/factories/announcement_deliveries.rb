FactoryBot.define do
  factory :announcement_delivery do
    announcement
    addresses { [ "a@example.com" ] }
  end
end
