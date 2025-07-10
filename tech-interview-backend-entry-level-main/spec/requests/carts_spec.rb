require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /cart" do  # Rota real do controller
    let!(:product) { create(:product, name: "Test Product", price: 10.0) }

    context 'when adding a new product to cart' do
      it 'creates a new cart item' do
        expect {
          post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        }.to change { Cart.count }.by(1)
        
        expect(response).to have_http_status(:success)
        cart = Cart.last
        cart_item = cart.cart_items.find_by(product: product)
        expect(cart_item.quantity).to eq(2)
      end
    end

    context 'when the product already is in the cart' do
      it 'updates the quantity of the existing item in the cart' do
        # Primeiro, cria um item no carrinho
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
        cart = Cart.last
        cart_item = cart.cart_items.find_by(product: product)
        initial_quantity = cart_item.quantity

        # Depois, adiciona mais do mesmo produto
        expect {
          post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json
        }.to change { cart_item.reload.quantity }.from(initial_quantity).to(initial_quantity + 2)
        
        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid parameters' do
      it 'returns error when product does not exist' do
        post '/cart', params: { product_id: 99999, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /cart/add_item" do  # Rota real para adicionar
    let!(:product) { create(:product, name: "Test Product", price: 10.0) }

    it 'sets quantity directly (não soma)' do
      # Primeiro, cria um carrinho
      post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      cart = Cart.last
      
      # Depois, define nova quantidade
      expect {
        post '/cart/add_item', params: { product_id: product.id, quantity: 5 }, as: :json
      }.to change { cart.cart_items.find_by(product: product).reload.quantity }.to(5)
      
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /cart" do
    let!(:cart) { create(:cart) }
    let!(:product1) { create(:product, name: "Product 1", price: 10.0) }
    let!(:product2) { create(:product, name: "Product 2", price: 20.0) }

    before do
      allow_any_instance_of(CartsController).to receive(:session).and_return({ cart_id: cart.id })
      create(:cart_item, cart: cart, product: product1, quantity: 2)
      create(:cart_item, cart: cart, product: product2, quantity: 1)
      cart.update_total_price!
    end

    it 'returns the cart with all items' do
      get '/cart', as: :json
      
      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      
      expect(json_response['products'].count).to eq(2)
      expect(json_response['total_price'].to_f).to eq(40.0)
    end
  end

 describe "DELETE /cart/:product_id" do
    let!(:cart) { create(:cart) }
    let!(:product) { create(:product, price: 15.0) }
    let!(:cart_item) { create(:cart_item, cart: cart, product: product, quantity: 3) }

    it 'removes the cart item completely' do
      # Primeiro, simula criação do carrinho via POST para estabelecer session
      post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      created_cart = Cart.last
      
      # Agora remove o item usando o endpoint correto
      expect {
        delete "/cart/remove_item", params: { product_id: product.id }, as: :json
      }.to change { created_cart.reload.cart_items.count }.by(-1)
      
      expect(response).to have_http_status(:success)
    end

    it 'handles cart with multiple products' do
      # Cria um carrinho com 2 produtos
      product2 = create(:product, price: 25.0)
      post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      post '/cart', params: { product_id: product2.id, quantity: 1 }, as: :json
      
      created_cart = Cart.last
      
      # Remove apenas um produto
      expect {
        delete "/cart/remove_item", params: { product_id: product.id }, as: :json
      }.to change { created_cart.reload.cart_items.count }.by(-1)
      
      expect(response).to have_http_status(:success)
      
      # Verifica que o outro produto ainda está lá
      expect(created_cart.reload.cart_items.find_by(product: product2)).to be_present
    end

    it 'returns error when product is not in cart' do
      # Cria um carrinho vazio primeiro
      post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      
      other_product = create(:product)
      delete "/cart/remove_item", params: { product_id: other_product.id }, as: :json
      expect(response).to have_http_status(:not_found)
    end
    
  end
end
