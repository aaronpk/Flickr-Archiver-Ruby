class Place
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => Resource

  property :name, String, :length => 255
  property :flickr_id, String, :length => 20
  property :woe_id, String, :length => 20

  property :num, Integer, :default => 0

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/place/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    self.name.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
  end

  def self.create_from_flickr(obj, user)
    place = Place.new
    place.user = user
    place.name = obj.name
    place.flickr_id = obj.place_id
    place.woe_id = obj.woe_id
    place
  end
end