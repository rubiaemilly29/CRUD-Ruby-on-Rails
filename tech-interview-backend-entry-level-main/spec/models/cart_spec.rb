require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'mark_as_abandoned!' do
    let(:shopping_cart) { create(:cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(updated_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned! }.to change { shopping_cart.abandoned }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:cart, abandoned: true, updated_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned!
      expect { shopping_cart.remove_if_abandoned! }.to change { Cart.count }.by(-1)
    end
  end

  describe 'update_total_price!' do
    let(:cart) { create(:cart) } 
      

    it 'updates the total_price of the cart' do
      cart.update(total_price: 100.0)
      expect { cart.update_total_price! }.to change { cart.total_price }.from(100.0).to(0.0)
    end
  end

  describe 'total_price' do
    let(:cart) { create(:cart) }
    let!(:product1) { create(:product, price: 10.0) }
    let!(:product2) { create(:product, price: 20.0) }

    before do
      create(:cart_item, cart: cart, product: product1, quantity: 1)
      create(:cart_item, cart: cart, product: product2, quantity: 1)
    end

    it 'calculates the total price of items in the cart' do
      cart.update_total_price!
      expect(cart.reload.total_price).to eq(30.0)
    end

    it 'updates total_price when items are added or removed' do
      product3 = create(:product, price: 15.0)
      create(:cart_item, cart: cart, product: product3, quantity: 1)
      
      cart.update_total_price!
      expect(cart.reload.total_price).to eq(45.0)

      cart.cart_items.find_by(product: product1).destroy
      cart.update_total_price!
      expect(cart.reload.total_price).to eq(35.0)
    end
  end

  # Testes de relacionamentos
  describe 'associations' do
    it 'has many cart_items' do
      cart = create(:cart)
      product = create(:product)
      cart_item = create(:cart_item, cart: cart, product: product)
      
      expect(cart.cart_items).to include(cart_item)
    end

    it 'has many products through cart_items' do
      cart = create(:cart)
      product = create(:product)
      create(:cart_item, cart: cart, product: product)
      
      expect(cart.products).to include(product)
    end

    it 'destroys dependent cart_items when cart is destroyed' do
      cart = create(:cart)
      product = create(:product)
      cart_item = create(:cart_item, cart: cart, product: product)
      
      expect { cart.destroy }.to change { CartItem.count }.by(-1)
    end
  end

  # Testes do scope
  describe 'scopes' do
    describe '.abandoned' do
      let!(:recent_cart) { create(:cart, updated_at: 1.hour.ago) }
      let!(:old_cart) { create(:cart, updated_at: 4.hours.ago) }

      it 'returns carts updated more than 3 hours ago' do
        expect(Cart.abandoned).to include(old_cart)
        expect(Cart.abandoned).not_to include(recent_cart)
      end
    end
  end

  # Testes da coluna abandoned
  describe 'abandoned attribute' do
    it 'defaults to false for new carts' do
      cart = create(:cart)
      expect(cart.abandoned).to be false
    end

    it 'can be set to true' do
      cart = create(:cart, abandoned: true)
      expect(cart.abandoned).to be true
    end
  end

  # Testes edge cases para remove_if_abandoned!
  describe 'remove_if_abandoned! edge cases' do
    it 'does not remove cart if not abandoned but old' do
      cart = create(:cart, abandoned: false, updated_at: 8.days.ago)
      expect { cart.remove_if_abandoned! }.not_to change { Cart.count }
    end

    it 'does not remove cart if abandoned but not old enough' do
      cart = create(:cart, abandoned: true, updated_at: 5.days.ago)
      expect { cart.remove_if_abandoned! }.not_to change { Cart.count }
    end

    it 'removes cart if abandoned and exactly 7 days old' do
      cart = create(:cart, abandoned: true, updated_at: 7.days.ago)
      expect { cart.remove_if_abandoned! }.to change { Cart.count }.by(-1)
    end
  end

  # Testes para carrinho vazio
  describe 'empty cart behavior' do
    let(:cart) { create(:cart) }

    it 'has zero total_price when empty' do
      cart.update_total_price!
      expect(cart.reload.total_price).to eq(0.0)
    end

    it 'can be marked as abandoned when empty' do
      expect { cart.mark_as_abandoned! }.to change { cart.reload.abandoned }.to(true)
    end
  end

end


