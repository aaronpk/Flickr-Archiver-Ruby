def load_user(username)
  @user = User.first :username => username
  raise FlickrArchivr::NotFoundError.new if @user.nil?
end

get '/:username/test/:id' do
  begin
    load_user params[:username]
    puts params
    'TESTING'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/?' do
  begin
    load_user params[:username]
    if @me && @me.id == @user.id 
      @photos = @user.photos.all(:order => [:date_uploaded.desc]).page(params[:page] || 1, :per_page => 9*4)
    else
      @photos = @user.photos.all(:public => true, :order => [:date_uploaded.desc]).page(params[:page] || 1, :per_page => 9*4)
    end
    erb :'photos/index'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/recent' do
  begin
    load_user params[:username]
    begin
      since = Time.now.to_i - 86400
      photos = @flickr.photos.recentlyUpdated :min_date => since, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
      @photos = []
      photos.each do |photo|
        p = {}
        p['class'] = "public"
        p['class'] = "private" if photo.ispublic == 0 && photo.isfriend == 0 && photo.isfamily == 0
        p['class'] = "friend" if photo.isfriend == 1
        p['class'] = "family" if photo.isfamily == 1
        p['class'] = "family friend" if photo.isfamily == 1 && photo.isfriend == 1
        p['photo'] = photo
        @photos.push p
      end
      erb :'photos/recent'
    rescue FlickRaw::FailedResponse => e
      puts "Error : #{e.msg}"
      @error = e
      erb :flickr_error
    end
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/photo/:id/?*' do
  begin
    load_user params[:username]
    @photo = Photo.first :id => params[:id]
    raise FlickrArchivr::NotFoundError.new if @photo.nil?
    @photo.verify_permission! @user, @me
    @photo_tags = @photo.tags.all(:machine_tag => false)
    @machine_tags = @photo.tags.all(:machine_tag => true)
    @people = @photo.people
    @photosets = @photo.photosets
    @places = @photo.places
    @has_location = @photo.latitude || @places.length > 0
    erb :'photos/view'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/person/:id/?*' do
  begin
    load_user params[:username]
    @person = Person.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @person.nil?
    @title = "Photos of #{@person.realname}"
    @photos = @person.photos
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/set/:id/?*' do
  begin
    load_user params[:username]
    @photoset = Photoset.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @photoset.nil?
    @title = @photoset.title
    @photos = @photoset.get_photos @me
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/place/:id/?*' do
  begin
    load_user params[:username]
    @place = Place.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @place.nil?
    @title = @place.name
    @photos = @place.get_photos @me
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/tag/:id/?*' do
  begin
    load_user params[:username]
    @tag = Tag.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @tag.nil?
    @tag.verify_permission! @user, @me
    @title = @tag.name
    @photos = @tag.get_photos @me
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

def format_text(text) 
  text.gsub(/\n/, '<br />')
end
