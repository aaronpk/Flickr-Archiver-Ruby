class PhotoPlace
  include DataMapper::Resource
  belongs_to :photo, :key => true
  belongs_to :place, :key => true
end