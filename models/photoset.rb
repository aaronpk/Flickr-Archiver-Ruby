class Photoset
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  has n, :photos, :through => Resource

  property :flickr_id, String, :length => 50, :index => true
  property :is_public, Boolean, :default => true

  property :title, String, :length => 255
  property :description, Text
  property :primary_flickr_id, String, :length => 50      # The Flickr id of the primary photo
  property :secret, String, :length => 50

  property :num, Integer, :default => 0
  property :flickr_views, Integer, :default => 0
  property :flickr_comments, Integer, :default => 0
  property :num_photos, Integer, :default => 0
  property :num_videos, Integer, :default => 0

  property :created_date, DateTime  # from Flickr
  property :updated_date, DateTime  # from Flickr

  property :sequence, Integer, :default => 0
  property :raw, Text

  include FlickrArchivr::PhotoList

  def display_name
    self.title
  end

  def list_type
    'set'
  end

  # Returns the relative link to this item's page on this website
  def page(photo=nil)
    "/#{self.username_from_id(self.user_id)}/set/#{self.id}/#{self.title_urlsafe}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def title_urlsafe
    self.title.gsub(/[^A-Za-z0-9_-]/, '-')
  end

  def verify_permission!(user, auth_user)
    raise FlickrArchivr::NotFoundError if self.user_id != user.id
    if auth_user
      # Disallow if the photo is not public and the authenticated user does not own the photo
      raise FlickrArchivr::ForbiddenError if !self.is_public && self.user_id != auth_user.id
    else
      # Disallow if the photo is not public
      raise FlickrArchivr::ForbiddenError if !self.is_public
    end
    true
  end

  def cover_photo
    cover = nil
    if self.primary_flickr_id
      cover = Photo.first :flickr_id => self.primary_flickr_id, :user => self.user
    end
    if cover.nil?
      cover = self.get_photos(nil, 1, 1)[0]
    end
    cover
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
          INNER JOIN `photo_photosets` ON `photos`.`id` = `photo_photosets`.`photo_id` 
          INNER JOIN `photosets` ON `photo_photosets`.`photoset_id` = `photosets`.`id`
          WHERE `photo_photosets`.`photoset_id` = ?
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
        INNER JOIN `photo_photosets` ON `photos`.`id` = `photo_photosets`.`photo_id` 
        INNER JOIN `photosets` ON `photo_photosets`.`photoset_id` = `photosets`.`id`
        WHERE `photo_photosets`.`photoset_id` = ?
          ' + (auth_user && auth_user.id == self.user_id ? '' : 'AND `photos`.`public` = 1') + '
        GROUP BY `photos`.`id`
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

  def count_public_photos
    repository.adapter.select('SELECT SUM(public) AS public
      FROM photos
      INNER JOIN photo_photosets ON photos.id = photo_photosets.photo_id 
      WHERE photo_photosets.photoset_id = ?', self.id)[0]
  end

  def self.create_from_flickr(obj, user)
    set = Photoset.new
    set.user = user
    set.flickr_id = obj.id
    set.title = obj.title
    set.primary_flickr_id = obj.primary
    set.secret = obj.secret
    set.description = obj.description if obj.respond_to?('description')
    set.num_photos = obj.count_photo if obj.respond_to?('count_photo')
    set.num_photos = obj.photos if obj.respond_to?('photos')
    set.num_videos = obj.count_video if obj.respond_to?('count_video')
    set.num_videos = obj.videos if obj.respond_to?('videos')
    set.flickr_views = obj.view_count if obj.respond_to?('view_count')
    set.flickr_views = obj.count_views if obj.respond_to?('count_views')
    set.flickr_comments = obj.comment_count if obj.respond_to?('comment_count')
    set.flickr_comments = obj.count_comments if obj.respond_to?('count_comments')
    set.created_date = Time.at(obj.date_create.to_i) if obj.respond_to?('date_create')
    set.updated_date = Time.at(obj.date_update.to_i) if obj.respond_to?('date_update')
    set.raw = obj.to_hash.to_json if obj.respond_to?('count_views')
    set
  end

  def update_from_flickr(obj)
    self.flickr_id = obj.id
    self.title = obj.title
    self.primary_flickr_id = obj.primary
    self.secret = obj.secret
    self.description = obj.description if obj.respond_to?('description')
    self.num_photos = obj.count_photo if obj.respond_to?('count_photo')
    self.num_photos = obj.photos if obj.respond_to?('photos')
    self.num_videos = obj.count_video if obj.respond_to?('count_video')
    self.num_videos = obj.videos if obj.respond_to?('videos')
    self.flickr_views = obj.view_count if obj.respond_to?('view_count')
    self.flickr_views = obj.count_views if obj.respond_to?('count_views')
    self.flickr_comments = obj.comment_count if obj.respond_to?('comment_count')
    self.flickr_comments = obj.count_comments if obj.respond_to?('count_comments')
    self.created_date = Time.at(obj.date_create.to_i) if obj.respond_to?('date_create')
    self.updated_date = Time.at(obj.date_update.to_i) if obj.respond_to?('date_update')
    self.raw = obj.to_hash.to_json if obj.respond_to?('count_views')
  end
end
