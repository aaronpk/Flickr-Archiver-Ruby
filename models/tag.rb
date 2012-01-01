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
  has n, :photos, :through => Resource

  include FlickrArchivr::PhotoList

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

  def page_for_photo(photo_id, per_page)
    repository.adapter.select('SELECT page_num FROM (
      SELECT (@row_num := @row_num + 1) AS row_num, FLOOR((@row_num-1) / ?) + 1 AS page_num, id, date_uploaded
      FROM (
        SELECT photos.id, photos.date_uploaded
        FROM `photos`
        JOIN (SELECT @row_num := 0) r
        INNER JOIN `photo_tags` ON `photos`.`id` = `photo_tags`.`photo_id` 
        INNER JOIN `tags` ON `photo_tags`.`tag_id` = `tags`.`id`
        WHERE `photo_tags`.`tag_id` = ?
        GROUP BY `photos`.`id`
        ORDER BY `photos`.`date_uploaded` DESC
      ) AS photo_list
    ) AS tmp
    WHERE id = ?
    ', per_page, self.id, photo_id)[0]
  end

  def self.create_from_flickr(obj, user)
    tag = Tag.new
    tag.user = user
    tag.machine_tag = obj.machine_tag
    tag.tag = obj._content
    tag.name = obj.raw
    tag
  end
end
