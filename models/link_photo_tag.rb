class PhotoTag
  include DataMapper::Resource
  belongs_to :photo, :key => true
  belongs_to :tag, :key => true
end