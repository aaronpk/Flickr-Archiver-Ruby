class Photo
  include DataMapper::Resource
  property :id, Serial
  property :flickr_id, String, :index => true

  property :title, String, :length => 255
  property :description, Text
  property :date_taken, DateTime
  property :date_uploaded, DateTime
  property :last_update, DateTime

  property :latitude, Float
  property :longitude, Float
  property :accuracy, Float

  property :public, Boolean
  property :friends, Boolean
  property :family, Boolean

  property :url_sq, String, :length => 255
  property :width_sq, Integer
  property :height_sq, Integer

  property :url_t, String, :length => 255
  property :width_t, Integer
  property :height_t, Integer

  property :url_s, String, :length => 255
  property :width_s, Integer
  property :height_s, Integer

  property :url_m, String, :length => 255
  property :width_m, Integer
  property :height_m, Integer

  property :url_z, String, :length => 255
  property :width_z, Integer
  property :height_z, Integer

  property :url_l, String, :length => 255
  property :width_l, Integer
  property :height_l, Integer

  property :url_o, String, :length => 255
  property :width_o, Integer
  property :height_o, Integer

  property :owner, String, :length => 20
  property :secret, String, :length => 20
  property :raw, Text
end