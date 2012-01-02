def load_user(username)
  @user = User.first :username => username
  raise FlickrArchivr::NotFoundError.new if @user.nil?
end

def per_page
  9 * 4
end

def per_page_small
  6 * 4
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
    if params[:show]
      params[:page] = @user.page_for_photo params[:show], per_page
    end
    @photos = @user.get_photos @me, params[:page], per_page
    erb :'photos/index'
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
    @list = Person.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @list.nil?
    @list.verify_permission! @user, @me
    @title = "Photos of #{@list.realname}"
    if params[:show]
      params[:page] = @list.page_for_photo params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/set/:id/?*' do
  begin
    load_user params[:username]
    @list = Photoset.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @list.nil?
    @list.verify_permission! @user, @me
    @title = @list.title
    if params[:show]
      params[:page] = @list.page_for_photo params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/place/:id/?*' do
  begin
    load_user params[:username]
    @list = Place.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @list.nil?
    @list.verify_permission! @user, @me
    @title = @list.name
    if params[:show]
      params[:page] = @list.page_for_photo params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/tag/:id/?*' do
  begin
    load_user params[:username]
    @list = Tag.first :id => params[:id], :user => @user
    raise FlickrArchivr::NotFoundError.new if @list.nil?
    @list.verify_permission! @user, @me
    @title = @list.name
    if params[:show]
      params[:page] = @list.page_for_photo params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small
    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/sets/?' do
  begin
    load_user params[:username]
    @sets = @user.get_sets @me, params[:page], 6*4
    @page = params[:page].to_i || 1
    erb :sets
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

def format_text(text) 
  text.gsub(/\n/, '<br />')
end
