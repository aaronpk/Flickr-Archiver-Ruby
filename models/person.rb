class Person
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => :person_photo

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100
  property :realname, String, :length => 100

  property :num, Integer, :default => 0

  include FlickrArchivr::PhotoList

  def display_name
    (self.realname && (!self.realname.empty?) ? self.realname : self.username)
  end

  def list_type
    'person'
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/person/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    if self.username
      self.username.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
    else
      self.realname.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
    end
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    true
  end

  def cover_photo
    puts "Retrieving cover photo for #{self.display_name}"
    self.get_photos(nil, 1, 1)[0]
  end

  # Return the next and previous n photos given this ordering
  def get_context(auth_user, photo_id, num)
    row_num = self.row_for_photo auth_user, photo_id
    repository.adapter.select('
      SELECT row_num, id, title, local_path_sq FROM (
        SELECT (@row_num := @row_num + 1) AS row_num, id, title, local_path_sq
        FROM (
          SELECT photos.id, photos.date_uploaded, photos.title, local_path_sq
          FROM `photos`
          JOIN (SELECT @row_num := 0) r
          INNER JOIN `person_photos` ON `photos`.`id` = `person_photos`.`photo_id` 
          INNER JOIN `people` ON `person_photos`.`person_id` = `people`.`id`
          WHERE `person_photos`.`person_id` = ?
            ' + (auth_user && auth_user.id == self.user_id ? '' : 'AND `photos`.`public` = 1') + '
          GROUP BY `photos`.`id`
          ORDER BY `photos`.`date_uploaded` DESC
        ) AS photo_list
      ) AS tmp
      WHERE row_num >= ? - ? AND row_num <= ? + ?
    ', self.id, row_num, num, row_num, num)
  end

  def _order_photos(col, auth_user, photo_id, per_page)
    repository.adapter.select('SELECT ' + col + ' FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        INNER JOIN `person_photos` ON `photos`.`id` = `person_photos`.`photo_id` 
        INNER JOIN `people` ON `person_photos`.`person_id` = `people`.`id`
        WHERE `person_photos`.`person_id` = ?
          ' + (auth_user && auth_user.id == self.user_id ? '' : 'AND `photos`.`public` = 1') + '
        GROUP BY `photos`.`id`
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

  def self.create_from_flickr(obj, user)
    person = Person.new
    person.user = user
    person.nsid = obj.nsid
    person.username = obj.username
    person.realname = obj.realname
    person
  end

  def update_count!
    self.num = PersonPhoto.count :person_id => self.id
    self.save
  end
end