class Photo
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  has n, :tags, :through => Resource
  has n, :sets, :through => Resource
  has n, :places, :through => Resource
  has n, :people, :through => :person_photo

  property :flickr_id, String, :length => 50, :index => true

  property :title, String, :length => 255
  property :description, Text
  property :date_taken, DateTime
  property :date_uploaded, DateTime
  property :last_update, DateTime

  property :latitude, Float
  property :longitude, Float
  property :accuracy, Float

  property :public, Boolean
  property :friends, Boolean
  property :family, Boolean

  property :url, String, :length => 255
  property :local_path, String, :length => 255

  property :url_sq, String, :length => 255
  property :width_sq, Integer
  property :height_sq, Integer

  property :url_t, String, :length => 255
  property :width_t, Integer
  property :height_t, Integer

  property :url_s, String, :length => 255
  property :width_s, Integer
  property :height_s, Integer

  property :url_m, String, :length => 255
  property :width_m, Integer
  property :height_m, Integer

  property :url_z, String, :length => 255
  property :width_z, Integer
  property :height_z, Integer

  property :url_l, String, :length => 255
  property :width_l, Integer
  property :height_l, Integer

  property :url_o, String, :length => 255
  property :width_o, Integer
  property :height_o, Integer

  property :owner, String, :length => 20
  property :secret, String, :length => 20
  property :raw, Text

  def self.sizes
    ['sq','t','s','m','z','l','o']
  end

  def self.create_from_flickr(obj, user)
    photo = Photo.new
    photo.user = user
    photo.flickr_id = obj.id
    photo.title = obj.title
    photo.description = obj.description
    photo.date_taken = Time.parse obj.dates.taken
    photo.date_uploaded = Time.at obj.dates.posted.to_i
    photo.last_update = Time.at obj.dates.lastupdate.to_i if obj.dates.lastupdate
    if obj.respond_to?('location')
      photo.latitude = obj.location.latitude
      photo.longitude = obj.location.longitude
      photo.accuracy = obj.location.accuracy
    end
    photo.public = obj.visibility.ispublic
    photo.friends = obj.visibility.isfriend
    photo.family = obj.visibility.isfamily
    photo.owner = obj.owner.nsid
    photo.secret = obj.secret
    photo.raw = obj.to_hash.to_json
    photo
  end
end