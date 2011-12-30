class PhotoPhotoset
  include DataMapper::Resource
  belongs_to :photo, :key => true
  belongs_to :photoset, :key => true
end