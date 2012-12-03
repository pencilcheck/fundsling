require 'sinatra/base'

require 'slim'
require 'sass'
require 'coffee-script'

require 'google4r/checkout'

require 'mongo'
require 'mongoid'
#require 'mongoid_money_field' # don't use it, it will prevent anything else from saving

require 'encrypted_cookie'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'

require './test/frontend_configuration'
require './taxtablefactory'

$stdout.sync = true

$frontend = Google4R::Checkout::Frontend.new(FRONTEND_CONFIGURATION)
$frontend.tax_table_factory = TaxTableFactory.new

Mongoid.load!("config/mongoid.yml")

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
        [self.cents, self.currency.mongoize]
    end

    class << self
        def demongoize(object)
            Money.new(object[0], Money::Currency.demongoize(object[1]))
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

class Order
    include Mongoid::Document
    field :notification_serial_number, type: String
    field :quantity, type: Integer
    field :unit_price, type: Money

    field :authorized_amount, type: Money
    field :autorization_expiration_date, type: DateTime

    embeds_one :order_summary
    embeds_one :product
end

class OrderSummary
    include Mongoid::Document

    field :user_id, type: Moped::BSON::ObjectId
    field :google_order_number, type: String
    field :buyer_billing_address, type: Google4R::Checkout::Address
    field :buyer_id, type: String
    field :buyer_shipping_address, type: Google4R::Checkout::Address
    field :financial_order_state, type: String
    field :fulfillment_order_state, type: String

    embedded_in :order
end

class Product
    include Mongoid::Document
    field :product_id, type: String
    field :name, type: String
    field :description, type: String
    field :number_in_stock, type: Integer
end

$pepsi_product = Product.create(name: '2-liter bottle of Diet Pepsi', 
        number_in_stock: 10,
        product_id: "1s3945GG0")
$number_of_pepsi = Order.count
$limit_of_pepsi = 10

class SassHandler < Sinatra::Base

    set :views, File.dirname(__FILE__) + '/views/scss'

    get '/css/*.css' do
        filename = params[:splat].first
        scss filename.to_sym
    end

end

class CoffeeHandler < Sinatra::Base

    set :views, File.dirname(__FILE__) + '/views/coffee'

    get "/js/*.js" do
        filename = params[:splat].first
        coffee filename.to_sym
    end
end

class FundslingApp < Sinatra::Base
    register Sinatra::SinatraAuthentication

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :views, File.dirname(__FILE__) + '/views'

    set :template_engine, :slim
    set :sinatra_authentication_view_path, File.expand_path('../views/authentication', __FILE__)

    use SassHandler
    use CoffeeHandler

    use Rack::Session::EncryptedCookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
    use Rack::Flash


    get '/' do
        purchases = logged_in? ? Order.where(user_id: current_user._id) : []
        slim :index, :layout => true, :locals => {:purchases => purchases}
    end

    get '/full' do
        slim :full, :layout => true
    end

    get '/create' do
        login_required
        
        redirect '/full' if $number_of_pepsi >= $limit_of_pepsi
        
        # Create a new checkout command (to place an order)
        cmd = $frontend.create_checkout_command

        # Add an item to the command's shopping cart
        cmd.shopping_cart.create_item do |item|
            item.name = "2-liter bottle of Diet Pepsi"
            item.quantity = 100
            item.unit_price = Money.new(0.00, "USD")
        end

        # Send the command to Google and capture the HTTP response
        begin
            response = cmd.send_to_google_checkout
        rescue Net::HTTPServerError => e
            # Sometimes Google Checkout is unavailable for internal reasons.
            # Because of this, it's a good idea to catch Net::HTTPServerError
            # and retry.

            response = cmd.send_to_google_checkout
        end

        # TODO:move this after using our own merchant information
        order = Order.new(
            user_id: current_user._id,
            quantity: 100,
            unit_price: Money.new(0.00, "USD"), 
            notification_serial_number: response.serial_number, 
            product: $pepsi_product
        )
        order.save!

        # TODO:remove this after using our own merchant information
        $number_of_pepsi += 1


        # Redirect the user to Google Checkout to complete the transaction
        redirect response.redirect_url
    end

    get '/number' do
        JSON.dump [$number_of_pepsi, $limit_of_pepsi - $number_of_pepsi]
    end

    post '/handler' do
        handler = $frontend.create_notification_handler
        
        begin
            notification = handler.handle(request.raw_post)
        rescue Google4R::Checkout::UnknownNotificationType
            puts 'cannot comprehend'
        end

        case notification
        when Google4R::Checkout::NewOrderNotification

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                order.order_summary = OrderSummary.new(
                    google_order_number: notification.google_order_number,
                    buyer_billing_address: notification.buyer_billing_address,
                    buyer_id: notification.buyer_id,
                    buyer_shipping_address: notification.buyer_shipping_address,
                    financial_order_state: notification.financial_order_state,
                    fulfillment_order_state: notification.fulfillment_order_state
                )
                order.save
                $number_of_pepsi += 1
            end

        when Google4R::Checkout::OrderStateChangeNotification

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                order.order_summary.financial_order_state = notification.new_finantial_order_state
                order.save
                if notification.new_finantial_order_state == 
                        Google4R::Checkout::FinancialOrderState::CANCELLED
                    order.delete
                    $number_of_pepsi -= 1
                end
            end

        when Google4R::Checkout::AuthorizationAmountNotification 

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                order.authorization_amount = notification.authorization_amount
                order.authorization_expiration_date = 
                    notification.authorization_expiration_date
                order.save
            end

            # ready to charge :)
            if $number_of_pepsi == $limit_of_pepsi
                # charge!
            end

        else
            puts 'no'
        end

        notification_acknowledgement = Google4R::Checkout::NotificationAcknowledgement.new(notification)

        content_type 'text/xml'
        notification_acknowledgement.to_xml
    end
end

if __FILE__ == $0
    FundslingApp.run! :port => ENV['PORT']
end
