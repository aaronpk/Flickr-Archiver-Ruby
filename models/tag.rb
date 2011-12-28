class Tag
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  property :flickr_id, String, :length => 50, :index => true
  property :tag, String, :length => 255, :index => true    # _content
  property :name, String, :length => 255                   # raw
  property :machine_tag, Boolean, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :photos, :through => Resource

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/tag/#{self.id}/#{self.tag}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  # Raise an exception if the given user is not authorized to view this photo.
  # Check both logged-out visitors, as well as cross-user permissions
  def is_authorized(user, auth_user)
    raise FlickrArchivr::ForbiddenError if self.user.id != user.id
    true
  end

  def self.create_from_flickr(obj, user)
    tag = Tag.new
    tag.user = user
    tag.flickr_id = obj.id
    tag.machine_tag = obj.machine_tag
    tag.tag = obj._content
    tag.name = obj.raw
    tag
  end
end

# TODO: Move flickr_id to the `photo_tags` table
