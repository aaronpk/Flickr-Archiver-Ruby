class Tag
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  property :flickr_id, String, :length => 50, :index => true
  property :tag, String, :length => 50, :index => true    # _content
  property :name, String, :length => 50                   # raw
  property :machine_tag, Boolean, :default => false
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :photos, :through => Resource

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
