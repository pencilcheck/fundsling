#!/usr/bin/env ruby

require 'date'
require 'mongo'
require 'mongoid'
require 'mongoid_paperclip'

require './models/mongoize'

require './models/preorder'

require './models/order'

require './models/ordersummary'

require './models/product'

require './models/picture'

Timeout.timeout(30) do # in seconds
    ENV["RACK_ENV"] = "production"
    Mongoid.load!("config/mongoid.yml")

    # ended is not an attribute
    # returns products approaching deadline
    Product.where(:shipped => false, 
            :deadline.lte => 3.days.from_now).each do |product|
        # check if any pending product is expiring
        # if there is, notify the producers
        # we don't have to set state, because this runs daily
        # we want to send daily warning emails to producers 
        # as deadline is approaching
        puts product.inspect
    end
end
