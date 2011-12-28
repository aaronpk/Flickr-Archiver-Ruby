class Photoset
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  has n, :photos, :through => Resource

  property :flickr_id, String, :length => 50, :index => true

  property :title, String, :length => 255
  property :description, Text
  property :secret, String, :length => 50

  property :num, Integer, :default => 0

  property :created_date, DateTime  # from Flickr
  property :updated_date, DateTime  # from Flickr

  def get_photos(auth_user)
    if auth_user && auth_user.id == self.user_id
      self.photos
    else
      self.photos.all(:public => true)
    end
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/set/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    self.title.gsub(/[^A-Za-z0-9_-]/, '-')
  end

  # Raise an exception if the given user is not authorized to view this photo.
  # Check both logged-out visitors, as well as cross-user permissions
  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    if auth_user
      # Disallow if the photo is not public and the authenticated user does not own the photo
      raise FlickrArchivr::ForbiddenError if !self.public && self.user_id != auth_user.id
    else
      # Disallow if the photo is not public
      raise FlickrArchivr::ForbiddenError if !self.public
    end
    true
  end

  def self.create_from_flickr(obj, user)
    set = Photoset.new
    set.user = user
    set.flickr_id = obj.id
    set.title = obj.title
    set.secret = obj.secret
    set
  end
end