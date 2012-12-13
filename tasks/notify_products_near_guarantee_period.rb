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
    # return those that have been live for 7 or more days
    Product.where(:shipped => false, 
            :updated_at.lte => 7.days.ago).each do |product|
        # notify the producers once
        puts product.inspect
    end
end

