require 'sinatra/base'
require 'sinatra/session'
require 'sinatra/cookies'
require 'sinatra/reloader'
require 'better_errors'

require 'date'

require 'mongoid_paperclip'

require 'pony'

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

class PreOrder
    include Mongoid::Document
    include Mongoid::Timestamps
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :notification_serial_number, type: String
    field :quantity, type: Integer, default: 1
    field :product_id, type: Moped::BSON::ObjectId
end

class Order
    include Mongoid::Document
    include Mongoid::Timestamps
    field :preorder_id, type: Moped::BSON::ObjectId
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :quantity, type: Integer, default: 1

    field :authorized_amount, type: Money
    field :autorization_expiration_date, type: DateTime

    embeds_one :order_summary
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
    field :user_id, type: Moped::BSON::ObjectId
    field :session_name, type: String
    field :name, type: String
    field :unit_price, type: Money
    field :description, type: String
    field :number_in_stock, type: Integer
    field :limit_in_stock, type: Integer
    field :deadline, type: DateTime, default: DateTime.now
    field :youtube_link, type: String
    field :number_of_purchases, type: Integer, default: 0
    field :public_link_id, type: String

    embeds_many :pictures, :cascade_callbacks => true
end

class Picture
    include Mongoid::Document
    include Mongoid::Paperclip
    include Mongoid::Timestamps
    has_mongoid_attached_file :file,
        :url            => "/picture/:attachment/:id/:style/:basename.:extension",
        :path           => "/public/picture/:attachment/:id/:style/:basename.:extension"

    embedded_in :product, :inverse_of => :pictures
end

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
    configure do
        Dust.config.template_root = File.expand_path('../views/dust/', __FILE__)
        BetterErrors.application_root = File.expand_path("..", __FILE__)
        register Sinatra::SinatraAuthentication
        register Sinatra::Session
        register Dust::Sinatra
    end

    configure :development do
        register Sinatra::Reloader
    end

    configure :production do
        Pony.options = {
            :via => :smtp,
            :via_options => {
                :address => 'smtp.sendgrid.net',
                :port => '587',
                :domain => 'heroku.com',
                :user_name => ENV['SENDGRID_USERNAME'],
                :password => ENV['SENDGRID_PASSWORD'],
                :authentication => :plain,
                :enable_starttls_auto => true
            }
        }
    end

    helpers Sinatra::Cookies

    enable :sessions

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :views, File.dirname(__FILE__) + '/views'

    set :template_engine, :slim
    set :sinatra_authentication_view_path, File.expand_path('../views/authentication', __FILE__)
    set :remote_sandbox, true


    use SassHandler
    use CoffeeHandler
    use DustHandler

    use BetterErrors::Middleware
    use Rack::Session::EncryptedCookie, :secret => 'A1 sauce 1s so good you should use 1t on a11 yr st34ksssss'
    use Rack::Flash

    # Local helpers
    helpers do
        def make_paperclip_mash(file_hash)
            mash = Mash.new
            mash['tempfile'] = file_hash[:tempfile]
            mash['filename'] = file_hash[:filename]
            mash['content_type'] = file_hash[:type]
            mash['size'] = file_hash[:tempfile].size
            mash
        end

        def valid_order?(order_id)
            unless Order.where(_id: order_id).exists?
                flash[:error] = "Sorry, no order found."
                unless back.nil?
                    redirect back
                else
                    redirect '/'
                end
            end
        end

        def valid_product?(product_id)
            unless Product.where(_id: product_id).exists?
                flash[:error] = "Sorry, no product found."
                unless back.nil?
                    redirect back
                else
                    redirect '/'
                end
            end
        end

        def valid_public_link_id?(link_id)
            unless Product.where(public_link_id: link_id).exists?
                flash[:error] = "Sorry, no product found."
                unless back.nil?
                    redirect back
                else
                    redirect '/'
                end
            end
        end

        def owner?(product_id)
            if logged_in?
                unless Product.where(_id: product_id, user_id: current_user._id).exists?
                    redirect '/login' 
                    return false
                end
            else
                unless Product.where(_id: product_id, session_name: session[:name]).exists?
                    redirect '/login' 
                    return false
                end
            end
            return true
        end
    end

    before do
        unless session?
            session_start! 
            unless logged_in?
                session[:name] = (0...8).map{65.+(rand(26)).chr}.join
            else
                session[:name] = current_user.session_name
            end
        end
    end

## Public pages

    # public product listing (homepage)
    # product landing page too
    get '/?' do
        if params.flatten.empty?
            slim :index, :layout => true
        else
            valid_public_link_id? params.flatten[0]
            product = Product.where(public_link_id: params.flatten[0]).first
            slim :product, :layout => true, :locals => {:product => product}
        end
    end

    get '/invite/?' do
        slim :invite, :layout => true
    end

    # create product page
    get '/power/?' do
        slim :power, :layout => true
    end

    # cart page, showing all orders
    # or order detail page
    get '/cart/?' do
        if params.flatten.empty?
            unless logged_in?
                purchases = Order.where(user_id: current_user._id).entries
            else
                purchases = Order.where(session_name: session[:name]).entries
            end
            slim :cart, :layout => true, :locals => {:purchases => purchases}
        else
            valid_order? params.flatten[0]
            order = Order.where(_id: params.flatten[0])
            slim :order, :layout => true, :locals => {:order => order}
        end

    end

# Products

    # ajax create
    post '/products/?' do
        puts params.inspect

        product = Product.new(
            user_id: logged_in? ? current_user._id : nil,
            session_name: session[:name],
            name: params[:name],
            description: params[:description],
            deadline: DateTime.parse(params[:deadline]),
            unit_price: Money.parse("$" + params[:unit_price]),
            number_in_stock: params[:number_in_stock].to_i,
            limit_in_stock: params[:limit_in_stock].to_i,
            youtube_link: params[:youtube_link],
            number_of_purchases: 0,
            public_link_id: (0...6).map{65.+(rand(26)).chr}.join
        )
        product.save

        if params.has_key? :file
            tmpfile = params[:file][:tempfile]
            name = params[:file][:filename]

            puts "has attachments"
            product.update_attributes(pictures: 
                    [Picture.new(:file => make_paperclip_mash(params[:file]))])
            product.save
        end

=begin
        Pony.mail :to => '',
                  :from => 'support@power.com',
                  :subject => 'Welcome to Power!',
                  :body => slim("email/product_created".to_sym)
=end

        product.as_document.to_json
    end

    # ajax read, later there should be distinctions
    get '/products/:_id/?' do
        #if request.xhr?
        if not params.key? :_id or params[:_id] == "undefined"
            return JSON.dump Product.desc(:created_at).map! {|x| x.as_document}
        end

        if Product.where(_id: params[:_id]).exists?
            product = Product.where(_id: params[:_id]).first
            product.as_document.to_json
        end
    end

# Orders

    # ajax create order
    get '/orders/create/:product_id/?' do
        valid_product?(params[:product_id])
        product = Product.where(_id: params[:product_id]).first

        product_ordered = product.number_of_purchases
        product_in_stock = product.number_in_stock

        if product_ordered >= product_in_stock
            flash[:error] = "This product is already full, please try it next time."
            redirect back 
        end

        puts 'frontend'
        if settings.development?
            require './test/frontend_configuration'
        else
            FRONTEND_CONFIGURATION =
            {
                :merchant_id => settings.remote_sandbox ? ENV['SANDBOX_GOOGLE_CHECKOUT_ID'] : ENV['PRODUCTION_GOOGLE_CHECKOUT_ID'],
                :merchant_key => settings.remote_sandbox ? ENV['SANDBOX_GOOGLE_CHECKOUT_KEY'] : ENV['PRODUCTION_GOOGLE_CHECKOUT_KEY'],
                :use_sandbox => settings.remote_sandbox
            }
        end
        $frontend = Google4R::Checkout::Frontend.new(FRONTEND_CONFIGURATION)
        $frontend.tax_table_factory = TaxTableFactory.new

        
        # Create a new checkout command (to place an order)
        cmd = $frontend.create_checkout_command

        # Add an item to the command's shopping cart
        cmd.shopping_cart.create_item do |item|
            item.name = product.name
            item.quantity = params[:purchases]
            item.unit_price = product.unit_price
        end

        # Send the command to Google and capture the HTTP response
        begin
            response = cmd.send_to_google_checkout
        rescue Net::HTTPServerError => e
            # Sometimes Google Checkout is unavailable for internal reasons.
            # Because of this, it's a good idea to catch Net::HTTPServerError
            # and retry.

            puts 'error occurred when sending to google checkout, trying again'
            puts e
            response = cmd.send_to_google_checkout
        end

        # NOTE: Order will be created after receiving notification from Google
        preorder = PreOrder.new(
            user_id: logged_in? ? current_user._id : nil,
            session_name: session[:name],
            notification_serial_number: response.serial_number, 
            product_id: product._id,
            quantity: params[:purchases]
        )
        preorder.save!

        # Return url to redirect the user to Google Checkout 
        # to complete the transaction
        response.redirect_url
    end

    # update sorta...
    post '/handler/?' do
        handler = $frontend.create_notification_handler
        
        puts 'received an notification'
        begin
            notification = handler.handle(request.raw_post)
        rescue Google4R::Checkout::UnknownNotificationType
            puts 'cannot comprehend'
            return
        end

        case notification
        when Google4R::Checkout::NewOrderNotification

            puts 'new order notification'
            PreOrder.find_by(
                    notification_serial_number: notification.serial_number) do |preorder|
                product = Product.where(_id: preorder.product_id)

                product.number_in_stock -= 1
                product.number_of_purchases += 1

                order = Order.new(
                    preorder_id: preorder._id,
                    user_id: preorder.user_id,
                    session_name: preorder.session_name,
                    quantity: preorder.quantity,
                    product: product
                )
                order.order_summary = OrderSummary.new(
                    google_order_number: notification.google_order_number,
                    buyer_billing_address: notification.buyer_billing_address,
                    buyer_id: notification.buyer_id,
                    buyer_shipping_address: notification.buyer_shipping_address,
                    financial_order_state: notification.financial_order_state,
                    fulfillment_order_state: notification.fulfillment_order_state
                )
                order.save

                product.save
            end

        when Google4R::Checkout::OrderStateChangeNotification

            puts 'order state change notification'
            PreOrder.find_by(
                    notification_serial_number: notification.serial_number) do |preorder|
                product = Product.where(_id: preorder.product_id)

                order = Order.where(preoder_id: preorder._id)

                order.order_summary.financial_order_state = notification.new_finantial_order_state
                order.save
                if notification.new_finantial_order_state == 
                        Google4R::Checkout::FinancialOrderState::CANCELLED
                    order.delete

                    product.number_in_stock += 1
                    product.number_of_purchases -= 1
                    product.save
                end
            end

        when Google4R::Checkout::AuthorizationAmountNotification 

            puts 'authorization amount notification'
            PreOrder.find_by(
                    notification_serial_number: notification.serial_number) do |preorder|
                product = Product.where(_id: preorder.product_id)

                order = Order.where(preoder_id: preorder._id)

                order.authorization_amount = notification.authorization_amount
                order.authorization_expiration_date = 
                    notification.authorization_expiration_date
                order.save

                # ready to charge :)
                if product.number_in_stock == 0
                    # time to charge!
                    puts 'should charge here'
                end

            end

        else
            puts 'no'
        end

        notification_acknowledgement = Google4R::Checkout::NotificationAcknowledgement.new(notification)

        content_type 'text/xml'
        notification_acknowledgement.to_xml
    end

    # read one or all
    get '/orders/:_id/?' do
        #if request.xhr?
        if not params.key? :_id or params[:_id] == "undefined"
            if logged_in?
                return JSON.dump Order.where(user_id: current_user._id).desc(:created_at).map! {|x| x.as_document}
            else
                return JSON.dump Order.where(session_name: session[:name]).desc(:created_at).map! {|x| x.as_document}
            end
        end

        valid_order?(params[:_id]) and owner? params[:_id]

        if logged_in?
            if Order.where(_id: params[:_id], user_id: current_user._id).exists?
                order = Order.where(_id: params[:_id], user_id: current_user._id).first
                order.as_document.to_json
            end
        else
            if Order.where(_id: params[:_id], session_name: session[:name]).exists?
                order = Order.where(_id: params[:_id], session_name: session[:name]).first
                order.as_document.to_json
            end
        end
    end

    # remove
    delete '/orders/:_id/?' do
        valid_order?(params[:_id]) and owner? params[:_id]
        
        Order.where(_id: params[:_id]).first.delete

        true
    end



## Private pages

    # dashboard
    get '/icecream/?' do
        login_required and current_user.admin?
        slim :index, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    # show all orders
    get '/icecream/orders/?' do
        login_required and current_user.admin?
        slim :orders, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    # show all products
    get '/icecream/products/?' do
        login_required and current_user.admin?
        slim :products, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

    # show all registered users
    get '/icecream/users/?' do
        login_required and current_user.admin?
        slim :users, :views => File.dirname(__FILE__) + '/views/admin', :layout => true
    end

# Orders

    # read one or all
    get '/icecream/orders/:_id/?' do
        login_required and current_user.admin?

        #if request.xhr?
        if not params.key? :_id or params[:_id] == "undefined"
            return JSON.dump Order.all.desc(:created_at).map! {|x| x.as_document}
        end

        valid_order?(params[:_id])

        if Order.where(_id: params[:_id]).exists?
            order = Order.where(_id: params[:_id]).first
            order.as_document.to_json
        end
    end

    # update
    put '/icecream/orders/:_id/?' do
        login_required and current_user.admin?
        valid_order?(params[:_id])

        order = Order.where(_id: params[:_id]).first

        order.update_attributes(params)

        order.as_document.to_json
    end

    # remove
    delete '/icecream/orders/:_id/?' do
        login_required and current_user.admin?
        valid_order?(params[:_id])
        
        Order.where(_id: params[:_id]).first.delete

        true
    end


# Products

    # create
=begin
    post '/icecream/products/?' do
        login_required and current_user.admin?
        valid_product?(params[:_id])

        product = Product.new(
            name: params[:name],
            unit_price: Money.parse("$" + params[:unit_price]),
            number_in_stock: params[:number_in_stock].to_i,
            number_of_purchases: 0
        )
        product.save

        product.as_document.to_json
    end
=end

    # read one or all
    get '/icecream/products/:_id/?' do
        login_required and current_user.admin?
        valid_product?(params[:_id])

        #if request.xhr?
        if not params.key? :_id or params[:_id] == "undefined"
            return JSON.dump Product.all.desc(:created_at).map! {|x| x.as_document}
        end

        if Product.where(_id: params[:_id]).exists?
            product = Product.where(_id: params[:_id]).first
            product.as_document.to_json
        end
    end

    # update
    put '/icecream/products/:_id/?' do
        login_required and current_user.admin?
        valid_product?(params[:_id])

        product = Product.where(_id: params[:_id]).first

        product.update_attributes(params)

        product.as_document.to_json
    end

    # remove
    delete '/icecream/products/:_id/?' do
        login_required and current_user.admin?
        valid_product?(params[:_id])
        
        Product.where(_id: params[:_id]).first.delete

        true
    end
end

puts 'Mongoid'
Mongoid.load!("config/mongoid.yml")


if __FILE__ == $0
    FundslingApp.run! :port => ENV['PORT']
end
