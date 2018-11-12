class Photo
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  belongs_to :owner, 'Person'
  has n, :tags, :through => Resource
  has n, :photosets, :through => Resource
  has n, :places, :through => Resource
  has n, :people, :through => :person_photo

  property :flickr_id, String, :length => 50, :index => true
  property :username, String, :length => 100    # Username of the photo's owner. Used to avoid a DB lookup when creating links to the photo

  property :title, String, :length => 512
  property :description, Text
  property :date_taken, DateTime
  property :date_uploaded, DateTime
  property :last_update, DateTime

  property :media, String, :length => 50, :default => "photo", :index => true
  property :format, String, :length => 10, :default => "jpg"

  property :latitude, Float
  property :longitude, Float
  property :accuracy, Float

  property :public, Boolean
  property :friends, Boolean
  property :family, Boolean

  property :geo_public,  Boolean
  property :geo_friend, Boolean
  property :geo_family,  Boolean
  property :geo_contact, Boolean

  property :url, String, :length => 255

  property :url_sq, String, :length => 255
  property :local_path_sq, String, :length => 512
  property :width_sq, Integer
  property :height_sq, Integer

  property :url_t, String, :length => 255
  property :local_path_t, String, :length => 512
  property :width_t, Integer
  property :height_t, Integer

  property :url_s, String, :length => 255
  property :local_path_s, String, :length => 512
  property :width_s, Integer
  property :height_s, Integer

  property :url_m, String, :length => 255
  property :local_path_m, String, :length => 512
  property :width_m, Integer
  property :height_m, Integer

  property :url_z, String, :length => 255
  property :local_path_z, String, :length => 512
  property :width_z, Integer
  property :height_z, Integer

  property :url_l, String, :length => 255
  property :local_path_l, String, :length => 512
  property :width_l, Integer
  property :height_l, Integer

  property :url_o, String, :length => 255
  property :local_path_o, String, :length => 512
  property :width_o, Integer
  property :height_o, Integer

  property :local_path_v, String, :length => 512

  property :secret, String, :length => 20
  property :original_secret, String, :length => 20
  property :raw, Text

  def get_class
    klass = "public"
    klass = "private" if !self.public && !self.friends && !self.family
    klass = "friend" if self.friends
    klass = "family" if self.family
    klass = "family friend" if self.family && self.friends
    klass
  end

  # Returns the relative path for the photo at the requested size.
  # This path is safe for URLs as well as filesystem access
  def path(size)
    self.username + '/' + self.date_taken.strftime('%Y/%m/%d/') + size + '/'
  end

  # Returns just the filename portion for the photo. This will be 
  # appended to URL and filesystem paths.
  def filename(size)
    if size == 'v'
      secret = self.original_secret
      ext = 'mp4'
    elsif size == 'o'
      secret = self.original_secret
      ext = self.format
    else
      secret = self.secret
      ext = 'jpg';
    end
    self.flickr_id + '_' + secret + '_' + self.filename_from_title + ".#{ext}"
  end

  # Returns the absolute path to the folder containing the jpg
  def abs_path(size)
    SiteConfig.photo_root + self.path(size)
  end

  # Returns the absolute filename to the jpg
  def abs_filename(size)
    self.abs_path(size) + self.filename(size)
  end

  # Returns the full URL to the jpg
  def full_url(size)
    SiteConfig.photo_url_root + self.path(size) + self.filename(size)
  end

  # Generate a URL-and-filesystem-safe filename given the photo title.
  # Remove trailing file extension, and remove all non-basic characters.
  def filename_from_title
    Photo.filename_from_title self.title
  end

  def self.filename_from_title(title)
    title.sub(/\.(jpg|png|gif)$/i, '').gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-').sub(/-$/, '')[0,350]
  end

  # Returns the relative link to this photo's page on this website
  def page(list=nil)
    Photo.page self.username, self.id, self.filename_from_title, list
  end

  def self.page(username, id, title, list=nil)
    "/#{username}/photo/#{id}/#{Photo.filename_from_title(title)}" + (list ? "?#{list.list_type}=#{list.id}" : "")
  end

  # Return attributes for width and height for inserting into an <img> tag
  def wh_attr(size)
    if self.send('width_'+size)
      "width=\"#{self.send('width_'+size)}\" height=\"#{self.send('height_'+size)}\""
    else
      ''
    end
  end

  def width(size)
    self.send("width_#{size}")
  end

  def height(size)
    self.send("height_#{size}")
  end

  # Return a complete image tag for the best version of the photo that fits within the requested size
  def img_tag(size)
    # Iterate through self.sizes backwards starting from #{size}
    # Find the first local path
    found_first_size = false
    img = ''
    actual_size = size
    Photo.sizes.reverse.each do |s|
      next if found_first_size == false && s != size
      next if img != ''
      found_first_size = true
      path = self.send('local_path_'+s)
      if !path.nil?
        img = path
        actual_size = s
      end
    end
    "<img src=\"#{SiteConfig.photo_url_root}#{img}\" #{self.wh_attr(actual_size)} />"
  end

  # Raise an exception if the given user is not authorized to view this photo.
  # Check both logged-out visitors, as well as cross-user permissions.
  # user is the requested user, auth_user is the logged-in user
  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    if auth_user
      # Disallow if the photo is not public and the authenticated user does not own the photo
      raise FlickrArchivr::ForbiddenError if !self.public && self.user_id != auth_user.id
    else
      # Disallow if the photo is not public
      raise FlickrArchivr::ForbiddenError if !self.public
    end
    true
  end

  def sizes
    response = []
    Photo.sizes.each do |s|
      response << s if self.send('local_path_'+s)
    end
    response
  end

  def self.sizes
    ['sq','t','s','m','z','l','o']
    #['sq','t','s','m','z','l']
  end

  def self.name_for_size(size)
    {
      'sq' => 'Square',
      't' => 'Tiny',
      's' => 'Small',
      'm' => 'Medium',
      'z' => 'Medium',
      'l' => 'Large',
      'o' => 'Original',
      'v' => 'Video'
    }[size]
  end

  def self.create_from_flickr(obj, user)
    photo = Photo.new
    photo.user = user
    photo.username = user.username
    photo.flickr_id = obj.id
    photo.title = obj.title
    photo.description = obj.description
    photo.format = obj.originalformat
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
    photo.secret = obj.secret
    photo.original_secret = obj.originalsecret
    photo.raw = obj.to_hash.to_json
    photo
  end

  def update_from_flickr(obj)
    self.title = obj.title
    self.description = obj.description
    self.format = obj.originalformat
    self.date_taken = Time.parse obj.dates.taken
    self.date_uploaded = Time.at obj.dates.posted.to_i
    self.last_update = Time.at obj.dates.lastupdate.to_i if obj.dates.lastupdate
    if obj.respond_to?('location')
      self.latitude = obj.location.latitude
      self.longitude = obj.location.longitude
      self.accuracy = obj.location.accuracy
    end
    self.public = obj.visibility.ispublic
    self.friends = obj.visibility.isfriend
    self.family = obj.visibility.isfamily
    self.secret = obj.secret
    self.original_secret = obj.originalsecret
    self.raw = obj.to_hash.to_json
  end
end
