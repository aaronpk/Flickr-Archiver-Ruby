class User
  include DataMapper::Resource
  property :id, Serial

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100

  property :import_timestamp, Integer, :default => 0
  property :last_photo_imported, String, :length => 50

  property :access_token, String, :length => 255
  property :access_secret, String, :length => 255

  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :photos
  has n, :places
  has n, :tags
  has n, :photosets
  has n, :people

  include FlickrArchivr::PhotoList

  def get_sets(auth_user, page, per_page)
    if auth_user && auth_user.id == self.id
      self.photosets.all(:order => [:sequence.asc, :updated_date.desc, :created_date.desc, :id.desc]).page(page || 1, :per_page => per_page)
    else
      self.photosets.all(:public => true, :order => [:sequence.asc, :updated_date.desc, :created_date.desc, :id.desc]).page(page || 1, :per_page => per_page)
    end
  end

  def page(photo=nil)
    "/#{self.username}" + (photo.nil? ? "" : "?show=#{photo.id}")
  end

  def page_for_photo(photo_id, per_page)
    repository.adapter.select('SELECT page_num FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        WHERE `photos`.`user_id` = ?
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

end