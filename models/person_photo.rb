class PersonPhoto
  include DataMapper::Resource
  property :x, Integer
  property :y, Integer
  property :w, Integer
  property :h, Integer
  belongs_to :photo, :key => true
  belongs_to :person, :key => true
end