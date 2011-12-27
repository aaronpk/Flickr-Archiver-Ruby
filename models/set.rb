class Set
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  has n, :photos, :through => Resource

  property :flickr_id, String, :length => 50, :index => true

  property :title, String, :length => 100
  property :description, Text
  property :secret, String, :length => 50

  property :created_date, DateTime  # from Flickr
  property :updated_date, DateTime  # from Flickr

  def self.create_from_flickr(obj, user)
    set = Set.new
    set.user = user
    set.flickr_id = obj.id
    set.title = obj.title
    set.secret = obj.secret
    set
  end
end