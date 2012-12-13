# Extending user model in authentication model
class MongoidUser
    field :session_name, type: String
    field :address, type: Google4R::Checkout::Address
    field :session_name, type: String

    def address=(new_address)
        self.address = Google4R::Checkout::Address.new
        self.address.address1 = new_address[:address1]
        self.address.address2 = new_address[:address2]
        self.address.city = new_address[:city]
        self.address.postal_code = new_address[:postal_code]
    end
end

