class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items
  scope :abandonados, -> { where("updated_at < ?", 3.hours.ago) }

  def update_total_price!
    update!(total_price: cart_items.includes(:product).sum { |item| item.quantity * item.product.price })
  end
end
