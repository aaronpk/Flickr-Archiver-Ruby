module FlickrArchivr

  module Model
    def get_photos(auth_user, page, per_page)
      if auth_user && auth_user.id == self.user_id
        self.photos.all(:order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      else
        self.photos.all(:public => true, :order => [:date_uploaded.desc]).page(page || 1, :per_page => per_page)
      end
    end
  end
  
end