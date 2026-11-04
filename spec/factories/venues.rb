FactoryBot.define do
  factory :venue do
    sequence(:name) { |n| "会場#{n}" }
    sequence(:short_name) { |n| "会場#{n}" }
    announcement_summary { "会場の概要" }
    announcement_detail { "会場の詳細" }
  end
end
