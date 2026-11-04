FactoryBot.define do
  factory :event do
    venue
    date { Date.current }
    schedule { "10:00-12:00" }
  end
end
