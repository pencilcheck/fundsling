require 'google4r/checkout'

class Money::Currency

    def mongoize
        [self.id]
    end

    class << self
        def demongoize(object)
            Money::Currency.new(object[0])
        end

        def mongoize(object)
            object.mongoize
        end

        def evolve(object)
            object.mongoize
        end
    end
end

class Money

    def mongoize
        [self.to_s, self.currency.mongoize] # amount and symbol such as :usd
    end

    class << self
        def demongoize(object)
            # turn currency into symbol like $ for USD
            Money.parse(Money::Currency.demongoize(object[1]).symbol + object[0])
        end

        def mongoize(object)
            object.mongoize
        end

        def evolve(object)
            object.mongoize
        end
    end
end

class Google4R::Checkout::Address

    def mongoize
        [self.address1, self.address2, self.company_name, self.contact_name, self.email, self.fax, self.phone, 
        self.address_id, self.city, self.country_code, self.postal_code, self.region]
    end

    class << self
        def demongoize(object)
            result = Address.new
            result.address1, result.address2, result.company_name, result.contact_name, result.email, result.fax, result.phone, result.address_id, result.city, result.country_code, result.postal_code, result.region = object
            result
        end

        def mongoize(object)
            object.mongoize
        end

        def evolve(object)
            object.mongoize
        end
    end
end

