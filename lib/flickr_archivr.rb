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
      if auth_user && auth_user.id == self.user_id
        self.photos.all(:order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      else
        self.photos.all(:public => true, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      end
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
