class Tag
  include DataMapper::Resource
  property :id, Serial
  belongs_to :user
  property :tag, String, :length => 255, :index => true    # _content
  property :name, String, :length => 255                   # raw
  property :machine_tag, Boolean, :default => false
  property :num, Integer, :default => 0
  property :created_at, DateTime
  property :updated_at, DateTime
  has n, :photos, :through => :photo_tag

  include FlickrArchivr::PhotoList

  def display_name
    self.name
  end

  def list_type
    'tag'
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/tag/#{self.id}/#{self.tag}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    true
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
          INNER JOIN `photo_tags` ON `photos`.`id` = `photo_tags`.`photo_id` 
          INNER JOIN `tags` ON `photo_tags`.`tag_id` = `tags`.`id`
          WHERE `photo_tags`.`tag_id` = ?
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
        INNER JOIN `photo_tags` ON `photos`.`id` = `photo_tags`.`photo_id` 
        INNER JOIN `tags` ON `photo_tags`.`tag_id` = `tags`.`id`
        WHERE `photo_tags`.`tag_id` = ?
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
      SELECT YEAR(date_taken) AS year
      FROM photos
      JOIN photo_tags lk ON photos.id = lk.photo_id
      WHERE lk.tag_id = ?
      GROUP BY year
      ORDER BY year DESC
    ', self.id)
    months = repository.adapter.select('
      SELECT YEAR(date_taken) AS year, MONTH(date_taken) AS month
      FROM photos
      JOIN photo_tags lk ON photos.id = lk.photo_id
      WHERE lk.tag_id = ?
      GROUP BY year, month
      ORDER BY year DESC, month DESC
    ', self.id)
    days = []
    # days = repository.adapter.select('
    #   SELECT YEAR(date_taken) AS year, MONTH(date_taken) AS month, DAY(date_taken) AS day
    #   FROM photos
    #   JOIN photo_tags lk ON photos.id = lk.photo_id
    #   WHERE lk.tag_id = ?
    #   GROUP BY year, month, day
    #   ORDER BY year DESC, month DESC, day DESC
    # ', self.id)
    {:years => years, :months => months, :days => days}
  end

  def self.create_from_flickr(obj, user)
    tag = Tag.new
    tag.user = user
    tag.machine_tag = obj.machine_tag
    tag.tag = obj._content
    tag.name = obj.raw
    tag
  end

  def update_count!
    self.num = PhotoTag.count :tag_id => self.id
    self.save
  end
end
