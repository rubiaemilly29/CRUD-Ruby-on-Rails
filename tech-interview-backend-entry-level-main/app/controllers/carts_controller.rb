class CartsController < ApplicationController
  before_action :set_cart

  # POST /cart
  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity += quantity
    cart_item.save!

    @cart.update_total_price!
    render json: cart_payload(@cart)
  end

  # GET /cart
  def show
    render json: cart_payload(@cart)
  end

  # POST /cart/add_item
  def add_item
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    cart_item = @cart.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity = quantity
    cart_item.save!

    @cart.update_total_price!
    render json: cart_payload(@cart)
  end

  # DELETE /cart/:product_id
  def remove_item
    cart_item = @cart.cart_items.find_by(product_id: params[:product_id])
    if cart_item
      cart_item.destroy
      @cart.update_total_price!
      render json: cart_payload(@cart)
    else
      render json: { error: "Produto não está no carrinho" }, status: :not_found
    end
  end

  private

  def set_cart
    @cart = Cart.find_or_create_by(id: session[:cart_id])
    session[:cart_id] ||= @cart.id
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
