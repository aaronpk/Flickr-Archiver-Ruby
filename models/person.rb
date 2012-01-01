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

  def list_type
    'person'
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/person/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    if self.username
      self.username
    else
      self.realname.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
    end
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    true
  end

  def page_for_photo(photo_id, per_page)
    repository.adapter.select('SELECT page_num FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        INNER JOIN `person_photos` ON `photos`.`id` = `person_photos`.`photo_id` 
        INNER JOIN `people` ON `person_photos`.`person_id` = `people`.`id`
        WHERE `person_photos`.`person_id` = ?
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

end