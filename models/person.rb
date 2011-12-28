class Person
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => :person_photo

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100
  property :realname, String, :length => 100

  property :num, Integer, :default => 0

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.user.username}/person/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    if self.username
      self.username
    else
      self.realname.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
    end
  end

  def self.create_from_flickr(obj, user)
    person = Person.new
    person.user = user
    person.nsid = obj.nsid
    person.username = obj.username
    person.realname = obj.realname
    person
  end

end