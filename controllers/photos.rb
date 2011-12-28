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
    # TODO: Filter public/private based on whether the user is logged in
    @photos = @user.photos
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
    @photo.is_authorized @user, @me
    @photo_tags = @photo.tags.all(:machine_tag => false)
    @machine_tags = @photo.tags.all(:machine_tag => true)
    @people = @photo.people.all
    @photosets = @photo.photosets.all
    puts @photosets
    erb :'photos/view'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/person/:id/?*' do
  begin
    load_user params[:username]
    @person = Person.first :id => params[:id], :user => @user
    erb :'person/view'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end
