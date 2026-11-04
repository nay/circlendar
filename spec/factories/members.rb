FactoryBot.define do
  factory :member do
    sequence(:name) { |n| "メンバー#{n}" }
    user { association :user, member: instance }
  end
end
