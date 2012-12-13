class OrderSummary
    include Mongoid::Document

    field :google_order_number, type: String
    field :buyer_billing_address, type: Google4R::Checkout::Address
    field :buyer_id, type: String
    field :buyer_shipping_address, type: Google4R::Checkout::Address
    field :financial_order_state, type: String
    field :fulfillment_order_state, type: String

    embedded_in :order
end

