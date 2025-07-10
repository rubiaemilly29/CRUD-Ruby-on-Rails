require 'rails_helper'

RSpec.describe CartItem, type: :model do
  # Testes de relacionamentos
  describe 'associations' do
    it 'belongs to cart' do
      association = described_class.reflect_on_association(:cart)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to product' do
      association = described_class.reflect_on_association(:product)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  # Testes de validações básicas
  describe 'validations' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    it 'is valid with valid attributes' do
      cart_item = build(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart_item).to be_valid
    end

    it 'requires a cart' do
      cart_item = build(:cart_item, cart: nil, product: product, quantity: 1)
      expect(cart_item).not_to be_valid
    end

    it 'requires a product' do
      cart_item = build(:cart_item, cart: cart, product: nil, quantity: 1)
      expect(cart_item).not_to be_valid
    end

    it 'requires a quantity' do
      cart_item = build(:cart_item, cart: cart, product: product, quantity: nil)
      expect(cart_item).not_to be_valid
    end

    it 'requires quantity to be positive' do
      cart_item = build(:cart_item, cart: cart, product: product, quantity: 0)
      expect(cart_item).not_to be_valid
    end
  end

  # Teste de funcionalidade básica
  describe 'functionality' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product, price: 15.0) }

    it 'can be created with valid attributes' do
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart_item.persisted?).to be true
      expect(cart_item.cart).to eq(cart)
      expect(cart_item.product).to eq(product)
      expect(cart_item.quantity).to eq(2)
    end

    it 'updates cart total when created' do
      expect {
        create(:cart_item, cart: cart, product: product, quantity: 2)
        cart.update_total_price!
      }.to change { cart.reload.total_price }.to(30.0)
    end
  end

  # Teste de integração
  describe 'integration with cart' do
    let(:cart) { create(:cart) }
    let(:product1) { create(:product, price: 10.0) }
    let(:product2) { create(:product, price: 20.0) }

    it 'allows multiple items in same cart' do
      cart_item1 = create(:cart_item, cart: cart, product: product1, quantity: 1)
      cart_item2 = create(:cart_item, cart: cart, product: product2, quantity: 1)
      
      expect(cart.cart_items).to include(cart_item1, cart_item2)
      expect(cart.products).to include(product1, product2)
    end

    it 'is destroyed when cart is destroyed' do
      cart_item = create(:cart_item, cart: cart, product: product1, quantity: 1)
      
      expect { cart.destroy }.to change { CartItem.count }.by(-1)
    end
  end
end