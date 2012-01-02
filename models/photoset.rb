class Photoset
  include DataMapper::Resource
  property :id, Serial

  belongs_to :user
  has n, :photos, :through => Resource

  property :flickr_id, String, :length => 50, :index => true

  property :title, String, :length => 255
  property :description, Text
  property :secret, String, :length => 50

  property :num, Integer, :default => 0

  property :created_date, DateTime  # from Flickr
  property :updated_date, DateTime  # from Flickr

  include FlickrArchivr::PhotoList

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
    true
  end

  def cover_photo
    self.get_photos(nil, 1, 1)[0]
  end

  def page_for_photo(photo_id, per_page)
    repository.adapter.select('SELECT page_num FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        INNER JOIN `photo_photosets` ON `photos`.`id` = `photo_photosets`.`photo_id` 
        INNER JOIN `photosets` ON `photo_photosets`.`photoset_id` = `photosets`.`id`
        WHERE `photo_photosets`.`photoset_id` = ?
        GROUP BY `photos`.`id`
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

  def self.create_from_flickr(obj, user)
    set = Photoset.new
    set.user = user
    set.flickr_id = obj.id
    set.title = obj.title
    set.secret = obj.secret
    set
  end
end