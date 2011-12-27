class Person
  include DataMapper::Resource
  property :id, Serial
  has n, :photos, :through => :person_photo

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100

  property :realname, String, :length => 100
end