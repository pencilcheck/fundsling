require 'sinatra/base'
require 'slim'
require 'sass'
require 'coffee-script'
require 'google4r/checkout'
require 'couchrest'
require 'couchrest_extended_document'

require './test/frontend_configuration'
require './taxtablefactory'

$stdout.sync = true

$frontend = Google4R::Checkout::Frontend.new(FRONTEND_CONFIGURATION)
$frontend.tax_table_factory = TaxTableFactory.new

SERVER = CouchRest.new( "#{ENV['CLOUDANT_URL']}:5984" )
$order_db = SERVER.database( "orders" )

class Order < CouchRest::ExtendedDocument

    use_database $order_db


    property :google_order_number
    property :notification_serial_number
    property :product, :cast_as => 'Product'
    property :quantity
    property :unit_price
    property :status, :default => Google4R::Checkout::NewOrderNotification
    timestamps!

end

class Product < Hash

    include ::CouchRest::CastedModel

    property :name
    property :description
    property :number_in_stock

end

$pepsi_product = Product.new(:name => '2-liter bottle of Diet Pepsi', :number_in_stock => 10)
$number_of_pepsi = 0
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

    use SassHandler
    use CoffeeHandler

    set :public_folder, File.dirname(__FILE__) + '/public'
    set :views, File.dirname(__FILE__) + '/views'

    get '/' do
        @limit = $limit_of_pepsi
        slim :index
    end

    get '/full' do
        slim :full
    end

    get '/create' do
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

=begin
        order = Order.new(
                :quantity => 100, :unit_price => Money.new(1.99, "USD"))
        order.google_order_number = cmd.google_order_number
        order.notification_serial_number = response.serial_number
        order.product = $pepsi_product
        order.save
=end


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
        when Google4R::Checkout::OrderStateChangeNotification
        when Google4R::Checkout::AuthorizationAmountNotification 
=begin
            if Order.all.map! {|x| x.notification_serial_number}.include? 
                    notification.serial_number
                $number_of_pepsi += 1
            end
=end
            $number_of_pepsi += 1

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
