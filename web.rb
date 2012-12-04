require 'sinatra/base'
require 'sinatra/session'

require 'slim'
require 'sass'
require 'coffee-script'
require 'dust-sinatra'

require 'google4r/checkout'

require 'mongo'
require 'mongoid'
#require 'mongoid_money_field' # don't use it, it will prevent anything else from saving

require 'encrypted_cookie'
require 'digest/md5'
require 'digest/sha1'
require 'rack-flash'
require 'sinatra-authentication'

require './test/frontend_configuration'
require './taxtablefactory'

$stdout.sync = true

# Small helpers
def get_next_random_product_id
    (0...8).map{65.+(rand(26)).chr}.join
end

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

class Order
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :notification_serial_number, type: String
    field :quantity, type: Integer

    field :authorized_amount, type: Money
    field :autorization_expiration_date, type: DateTime

    embeds_one :order_summary
    field :product_id, type: Moped::BSON::ObjectId
end

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

class Product
    include Mongoid::Document
    include Mongoid::Timestamps
    field :name, type: String
    field :unit_price, type: Money
    field :description, type: String
    field :number_in_stock, type: Integer
    field :number_of_purchases, type: Integer
end

# User authentication model
class MongoidUser
    field :session_name, type: String
end

class SassHandler < Sinatra::Base

    set :views, File.dirname(__FILE__) + '/views/scss'

    get '/scss/*.scss' do
        filename = params[:splat].first
        scss filename.to_sym
    end

end

class CoffeeHandler < Sinatra::Base

    set :views, File.dirname(__FILE__) + '/views/coffee'

    get "/coffee/*.coffee" do
        filename = params[:splat].first
        coffee filename.to_sym
    end
end

class DustHandler < Sinatra::Base
    include Dust::Sinatra::Helpers

    set :views, File.dirname(__FILE__) + '/views/dust'

    get "/dust/*.dust" do
        filename = params[:splat].first
        dust filename.to_sym
    end
end

class FundslingApp < Sinatra::Base
    register Sinatra::SinatraAuthentication
    register Sinatra::Session
    register Dust::Sinatra

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :views, File.dirname(__FILE__) + '/views'

    set :template_engine, :slim
    set :sinatra_authentication_view_path, File.expand_path('../views/authentication', __FILE__)

    configure do
        Dust.config.template_root = File.expand_path('../views/dust/', __FILE__)
    end

    use SassHandler
    use CoffeeHandler
    use DustHandler

    use Rack::Session::EncryptedCookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
    use Rack::Flash

    # Local helpers
    helpers do
        def valid_order?(order_id)
            order = Order.where(_id: order_id)
            unless order
                flash[:error] = "Sorry, no order found."
                redirect back 
            end
        end

        def valid_product?(product_id)
            product = Product.where(_id: product_id)
            unless product
                flash[:error] = "Sorry, no product found."
                redirect back 
            end
        end
    end

## Public pages

    # public product listing (homepage)
    get '/' do
        session_start!
        unless logged_in?
            session[:name] = (0...8).map{65.+(rand(26)).chr}.join
        else
            session[:name] = current_user.session_name
        end
        products = Product.all
        slim :index, :layout => true, :locals => {:products => products, :session => session}
    end

    # cart page
    get '/cart' do
        unless logged_in?
            purchases = Order.where(user_id: current_user._id).entries
        else
            purchases = Order.where(session_name: session[:name]).entries
        end
        slim :cart, :layout => true, :locals => {:purchases => purchases}
    end

    # order detail page
    get '/orders/:order_id' do
        valid_order?(params[:order_id])
        slim :order, :layout => true, :locals => {:order_id => params[:order_id]}
    end

    # product detail page
    get '/products/:product_id' do
        valid_product?(params[:product_id])
        slim :product, :layout => true, :locals => {:product_id => params[:product_id]}
    end

    # ajax create order
    get '/orders/create/:product_id' do
        valid_product?(params[:product_id])
        product = Product.where(_id: params[:product_id]).first

        puts product.inspect

        pepsi_ordered = product.number_of_purchases
        pepsi_in_stock = product.number_in_stock

        if pepsi_ordered >= pepsi_in_stock
            flash[:error] = "This product is already full, please try it next time."
            redirect back 
        end
        
        # Create a new checkout command (to place an order)
        cmd = $frontend.create_checkout_command

        # Add an item to the command's shopping cart
        cmd.shopping_cart.create_item do |item|
            item.name = product.name
            item.quantity = 1
            item.unit_price = product.unit_price
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

        order = Order.new(
            user_id: logged_in? ? current_user._id : nil,
            session_name: session[:name],
            quantity: 1,
            notification_serial_number: response.serial_number, 
            product_id: product._id
        )
        order.save!

        # Redirect the user to Google Checkout to complete the transaction
        redirect response.redirect_url
    end

    # ajax version of product information
    post '/products/:product_id' do
        valid_product?(params[:product_id])
        product = Product.where(_id: params[:product_id])
        JSON.dump product
    end

    post '/handler' do
        handler = $frontend.create_notification_handler
        
        begin
            notification = handler.handle(request.raw_post)
        rescue Google4R::Checkout::UnknownNotificationType
            puts 'cannot comprehend'
            return
        end

        case notification
        when Google4R::Checkout::NewOrderNotification

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                product = Product.where(_id: order.product_id)

                order.order_summary = OrderSummary.new(
                    google_order_number: notification.google_order_number,
                    buyer_billing_address: notification.buyer_billing_address,
                    buyer_id: notification.buyer_id,
                    buyer_shipping_address: notification.buyer_shipping_address,
                    financial_order_state: notification.financial_order_state,
                    fulfillment_order_state: notification.fulfillment_order_state
                )
                order.save

                product.number_in_stock -= 1
                product.number_of_purchases += 1
                product.save!
            end

        when Google4R::Checkout::OrderStateChangeNotification

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                product = Product.where(_id: order.product_id)

                order.order_summary.financial_order_state = notification.new_finantial_order_state
                order.save
                if notification.new_finantial_order_state == 
                        Google4R::Checkout::FinancialOrderState::CANCELLED
                    order.delete

                    product.number_in_stock += 1
                    product.number_of_purchases -= 1
                    product.save!
                end
            end

        when Google4R::Checkout::AuthorizationAmountNotification 

            Order.find_by(
                    notification_serial_number: notification.serial_number) do |order|
                product = Product.where(_id: order.product_id)

                order.authorization_amount = notification.authorization_amount
                order.authorization_expiration_date = 
                    notification.authorization_expiration_date
                order.save

                # ready to charge :)
                if product.number_in_stock == 0
                    # charge!
                end

            end

        else
            puts 'no'
        end

        notification_acknowledgement = Google4R::Checkout::NotificationAcknowledgement.new(notification)

        content_type 'text/xml'
        notification_acknowledgement.to_xml
    end


## Private pages

    # dashboard
    get '/icecream' do
        login_required and current_user.admin?
        slim :index, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    get '/icecream/products' do
        login_required and current_user.admin?
        slim :products, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    # returns a list of products in json format
    post '/icecream/products' do
        login_required and current_user.admin?
        JSON.dump Product.all.desc(:created_at).map! {|x| x.as_document}
    end

    post '/icecream/products/add' do
        login_required and current_user.admin?

        product = Product.create(
            name: params[:product][:name],
            unit_price: Money.parse("$" + params[:product][:unit_price_in_usd]),
            number_in_stock: params[:product][:in_stock].to_i,
            number_of_purchases: 0
        )

        JSON.dump product.as_document
    end

    # show all registered users
    get '/icecream/users' do
        login_required and current_user.admin?
        slim :users, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    # show all orders
    get '/icecream/orders' do
        login_required and current_user.admin?
        slim :orders, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end
end

$frontend = Google4R::Checkout::Frontend.new(FRONTEND_CONFIGURATION)
$frontend.tax_table_factory = TaxTableFactory.new

Mongoid.load!("config/mongoid.yml")


if __FILE__ == $0
    FundslingApp.run! :port => ENV['PORT']
end
