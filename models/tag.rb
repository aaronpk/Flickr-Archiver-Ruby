class Tag
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  property :flickr_id, String, :length => 50, :index => true
  property :tag, String, :length => 50, :index => true
  property :name, String, :length => 50
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :photos, :through => Resource
end