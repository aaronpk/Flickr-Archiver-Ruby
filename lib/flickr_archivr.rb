module FlickrArchivr

  module PhotoList
    @@usernames = {}

    def self.username_from_id(id)
      if @@usernames[id].nil?
        @@usernames[id] = User.get(id).username
      end
      @@usernames[id]
    end

    def username_from_id(id)
      FlickrArchivr::PhotoList.username_from_id id
    end

    def get_photos(auth_user, page, per_page)
      if auth_user && auth_user.id == (self.class == User ? self.id : self.user_id)
        self.photos.all(:order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      else
        self.photos.all(:public => true, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      end
    end

    def get_photos_for_date(auth_user, page, per_page, year, month=nil, day=nil)
      if year && month && day
        range = (DateTime.parse("#{year}-#{month}-#{day}")..DateTime.parse("#{year}-#{month}-#{day} 23:59:59"))
      elsif year && month
        if [1,3,5,7,8,10,12].include? month
          lastday = 31
        elsif month.to_i == 2
          if year.to_i % 4 == 0
            lastday = 29
          else
            lastday = 28
          end
        else
          lastday = 30
        end
        range = (DateTime.parse("#{year}-#{month}-01")..DateTime.parse("#{year}-#{month}-#{lastday} 23:59:59"))
      else
        range = (DateTime.parse("#{year}-01-01")..DateTime.parse("#{year}-12-31 23:59:59"))
      end

      if auth_user && auth_user.id == (self.class == User ? self.id : self.user_id)
        self.photos.all(:date_taken => range, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      else
        self.photos.all(:date_taken => range, :public => true, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      end
    end

    # Return the photo's sequence number given this ordering of photos
    def row_for_photo(auth_user, photo_id)
      _order_photos('row_num', auth_user, photo_id, 1)
    end

    # Return the page number the given photo appears on for this ordering of photos
    def page_for_photo(auth_user, photo_id, per_page)
      _order_photos('page_num', auth_user, photo_id, per_page)
    end
  end

  class Error < Exception

  end
  class NotFoundError < Error
    def erb_template
      "error/404"
    end
  end
  class ForbiddenError < Error
    def erb_template
      "error/403"
    end
  end
end
