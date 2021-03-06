class Order
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :notification_serial_number, type: String
    field :quantity, type: Integer, default: 1

    field :product_id, type: Moped::BSON::ObjectId

    field :authorized_amount, type: Money
    field :autorization_expiration_date, type: DateTime

    field :charged, type: Boolean, default: false

    embeds_one :order_summary
end

