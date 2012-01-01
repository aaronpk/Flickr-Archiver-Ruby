class Tag
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  property :tag, String, :length => 255, :index => true    # _content
  property :name, String, :length => 255                   # raw
  property :machine_tag, Boolean, :default => false
  property :num, Integer, :default => 0
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :photos, :through => Resource

  include FlickrArchivr::PhotoList

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/tag/#{self.id}/#{self.tag}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    true
  end

  def self.create_from_flickr(obj, user)
    tag = Tag.new
    tag.user = user
    tag.machine_tag = obj.machine_tag
    tag.tag = obj._content
    tag.name = obj.raw
    tag
  end
end
