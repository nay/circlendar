FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    role { "member" }
    confirmed_at { Time.current }
    member { association :member, user: instance, strategy: :build }

    trait :admin do
      role { "admin" }
    end

    trait :unconfirmed do
      confirmed_at { nil }

      after(:create) do |user|
        user.generate_confirmation_token!
      end
    end

    trait :disabled do
      disabled_at { Time.current }
    end

    trait :provisional do
      password { nil }
      provisional { true }
    end
  end
end
