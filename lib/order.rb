require 'csv'
require_relative 'customer'

VALID_STATUS = [:pending, :paid, :processing, :shipped, :complete]
TAX = 0.075

class Order
  attr_reader :id, :customer, :fulfillment_status
  attr_accessor :products

  def initialize(id, products, customer, fulfillment_status = :pending)
    raise ArgumentError.new("Not a valid status.") if !VALID_STATUS.include?(fulfillment_status)

    @id = id
    @products = products
    @customer = customer
    @fulfillment_status = fulfillment_status
  end

  def total
    subtotal = @products.sum { |product, price| price }
    tax = subtotal * TAX
    total = subtotal + tax

    return total.round(2)
  end

  def add_product(product_name, price)
    if @products.has_key?(product_name)
      raise ArgumentError.new("Product already exists.")
    else
      @products[product_name] = price
    end
  end

  def remove_product(product_name)
    if @products.has_key?(product_name)
      @products.delete(product_name)
    else
      raise ArgumentError.new("That product does not exist.")
    end
  end

  def self.get_products_hash(products)
    regex = /([\w\s]+):((\d*[.])?\d+)/

    return products.scan(regex).map { |product, price| [ product.to_s, price.to_f ] }.to_h
  end

  def self.all
    keys = [:id, :products, :customer, :fulfillment_status]

    return CSV.read('data/orders.csv').map do |order_array|
      order = keys.zip(order_array).to_h

      Order.new(
            order[:id].to_i,
            Order.get_products_hash(order[:products]),
            Customer.find(order[:customer].to_i),
            order[:fulfillment_status].to_sym
      )
    end
  end

  def self.find(id)
    all_orders = Order.all

    return all_orders.find { |order| order.id == id }
  end

  def self.find_by_customer(customer_id)
    all_orders = Order.all

    return all_orders.select { |order| order.customer.id == customer_id }
  end
end

