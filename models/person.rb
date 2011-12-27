class Person
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => :person_photo

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100

  property :realname, String, :length => 100

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/person/#{self.id}/#{self.username}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end
end