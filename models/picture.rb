class Picture
    include Mongoid::Document
    include Mongoid::Paperclip
    include Mongoid::Timestamps
    has_mongoid_attached_file :file,
        :url            => "/picture/:attachment/:id/:style/:basename.:extension",
        :path           => "/public/picture/:attachment/:id/:style/:basename.:extension"

    embedded_in :product, :inverse_of => :pictures
end

