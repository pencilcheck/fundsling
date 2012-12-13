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

Timeout.timeout(20) do # in seconds
    ENV["RACK_ENV"] = "production"
    Mongoid.load!("config/mongoid.yml")

    # Clean preorders that already pass the expiration, longer than 1 day
    PreOrder.delete_all(:created_at.lte => 1.day.ago)
end
