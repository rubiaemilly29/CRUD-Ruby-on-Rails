FactoryBot.define do
  factory :cart do
    total_price { 0.0 }
    updated_at { Time.current }
    abandoned { false }
  end
end