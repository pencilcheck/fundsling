class Product
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :name, type: String
    field :unit_price, type: Money
    field :description, type: String
    field :minimum_orders, type: Integer
    field :maximum_orders, type: Integer
    field :deadline, type: DateTime, default: DateTime.now
    field :youtube_link, type: String
    field :number_of_purchases, type: Integer, default: 0
    field :public_link_id, type: String
    field :charged_all, type: Boolean, default: false # in other words, capture funds
    field :shipped_all, type: Boolean, default: false

    def remaining
        self.maximum_orders - self.number_of_purchases
    end

    def ended
        self.charged_all and self.shipped_all
    end

    def listing_price
        listing_price_from_raw(self.unit_price)
    end

    embeds_many :pictures, :cascade_callbacks => true

    validates_presence_of :minimum_orders
    validates_presence_of :maximum_orders
    validates :minimum_orders, numericality:
        { less_than_or_equal_to: :maximum_orders }
end

