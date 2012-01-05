class Place
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  has n, :photos, :through => Resource

  property :type, String, :length => 20
  property :name, String, :length => 255
  property :flickr_id, String, :length => 30
  property :woe_id, String, :length => 30

  property :num, Integer, :default => 0
  property :created_at, DateTime
  property :updated_at, DateTime

  include FlickrArchivr::PhotoList

  def display_name
    self.name
  end

  def list_type
    'place'
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/place/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    self.name.gsub(/[^A-Za-z0-9_-]/, '-').gsub(/-+/, '-')
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    true
  end

  def page_for_photo(auth_user, photo_id, per_page)
    repository.adapter.select('SELECT page_num FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        INNER JOIN `photo_places` ON `photos`.`id` = `photo_places`.`photo_id` 
        INNER JOIN `places` ON `photo_places`.`place_id` = `places`.`id`
        WHERE `photo_places`.`place_id` = ?
          ' + (auth_user && auth_user.id == self.user_id ? '' : 'AND `photos`.`public` = 1') + '
        GROUP BY `photos`.`id`
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

  def get_all_dates
    years = repository.adapter.select('
      SELECT YEAR(date_taken) AS year, COUNT(1) AS num
      FROM photos
      JOIN photo_places lk ON photos.id = lk.photo_id
      WHERE lk.place_id = ?
      GROUP BY year
      ORDER BY year DESC
    ', self.id)
    months = repository.adapter.select('
      SELECT YEAR(date_taken) AS year, MONTH(date_taken) AS month, COUNT(1) AS num
      FROM photos
      JOIN photo_places lk ON photos.id = lk.photo_id
      WHERE lk.place_id = ?
      GROUP BY year, month
      ORDER BY year DESC, month DESC
    ', self.id)
    days = []
    # days = repository.adapter.select('
    #   SELECT YEAR(date_taken) AS year, MONTH(date_taken) AS month, DAY(date_taken) AS day
    #   FROM photos
    #   JOIN photo_places lk ON photos.id = lk.photo_id
    #   WHERE lk.place_id = ?
    #   GROUP BY year, month, day
    #   ORDER BY year DESC, month DESC, day DESC
    # ', self.id)
    {:years => years, :months => months, :days => days}
  end

  def self.create_from_flickr(type, obj, user)
    place = Place.new
    place.user = user
    place.type = type
    place.name = obj._content
    place.flickr_id = obj.place_id
    place.woe_id = (obj.respond_to?('woeid') ? obj.woeid : '')
    place
  end

  def update_count!
    self.num = PhotoPlace.count :place_id => self.id
    self.save
  end
end