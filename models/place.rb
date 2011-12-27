class Place
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => Resource

  property :name, String, :length => 100
  property :place_id, String, :length => 20
  property :woe_id, String, :length => 20
end