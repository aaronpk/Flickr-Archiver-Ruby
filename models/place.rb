class Place
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => Resource

  property :type, String, :length => 20
  property :name, String, :length => 255
  property :flickr_id, String, :length => 30
  property :woe_id, String, :length => 30

  property :num, Integer, :default => 0

  def get_photos(auth_user, page, per_page)
    if auth_user && auth_user.id == self.user_id
      self.photos.all(:order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
    else
      self.photos.all(:public => true, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
    end
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/place/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    self.name.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
  end

  def self.create_from_flickr(type, obj, user)
    place = Place.new
    place.user = user
    place.type = type
    place.name = obj._content
    place.flickr_id = obj.place_id
    place.woe_id = (obj.respond_to?('woeid') ? obj.woeid : '')
    place
  end
end