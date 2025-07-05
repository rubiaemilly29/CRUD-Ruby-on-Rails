class CartsController < ApplicationController
  before_action :set_cart

  # POST /cart - Requisito 1
  # Cria um carrinho de compras vazio e salva no session[:cart_id]
  # Se o carrinho não existir, cria um novo carrinho vazio
  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = (cart_item.quantity || 0) + quantity
    cart_item.save!

    @cart.update_total_price!
    render json: cart_payload(@cart)
  end

    # GET /cart - Requisito 2
  # Retorna o carrinho de compras atual

  def show
    render json: cart_payload(@cart)
  end

    # POST /cart/add_item - Requisito 3
  # Adiciona um item ao carrinho de compras

  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = quantity
    cart_item.save!

    @cart.update_total_price!
    render json: cart_payload(@cart)
  end

  private

  def set_cart
    if session[:cart_id]
      @cart = Cart.find_by(id: session[:cart_id])
      unless @cart
        @cart = Cart.create!(total_price: 0)
        session[:cart_id] = @cart.id
      end
    else
      @cart = Cart.create!(total_price: 0)
      session[:cart_id] = @cart.id
    end
  end

  def cart_payload(cart)
    {
      id: cart.id,
      products: cart.cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.price,
          total_price: item.quantity * item.product.price
        }
      end,
      total_price: cart.cart_items.includes(:product).sum { |item| item.quantity * item.product.price }
    }
  end
end
