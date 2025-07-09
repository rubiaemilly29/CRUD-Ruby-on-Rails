FactoryBot.define do
  factory :cart do
    total_price { 0 }
    abandoned { false }
  end
end