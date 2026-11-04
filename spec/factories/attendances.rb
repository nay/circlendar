FactoryBot.define do
  factory :attendance do
    event
    player factory: :member
  end
end
