
################################################################
## Photo detail page
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

################################################################
## Photo lists (user, person, tag, place, set)

get '/:username/?' do
  begin
    load_user params[:username]
    @list = @user
    @title = "#{@user.username}'s Photostream"
    if params[:show]
      params[:page] = @user.page_for_photo @me, params[:show], per_page_small
    end
    @photos = @user.get_photos @me, params[:page], per_page_small

    load_related_photos

    @related_titles = {
      :people => 'People in these photos',
      :sets => 'Sets in these photos',
      :tags => 'Tags in these photos',
      :places => 'Places in these photos'
    }

    erb :'photos/list'
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
    @title = "Photos of #{@list.display_name}"
    if params[:show]
      params[:page] = @list.page_for_photo @me, params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small

    load_related_photos
    @related_dates = @list.get_all_dates

    @related_titles = {
      :people => 'Related people',
      :sets => 'Sets with this person',
      :tags => 'Tags with this person',
      :places => 'Places this person appears in'
    }

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
      params[:page] = @list.page_for_photo @me, params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small

    load_related_photos
    @related_dates = @list.get_all_dates

    @related_titles = {
      :people => 'People in this set',
      :sets => 'Related sets',
      :tags => 'Tags in this set',
      :places => 'Places in this set'
    }

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
      params[:page] = @list.page_for_photo @me, params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small

    load_related_photos
    @related_dates = @list.get_all_dates

    @related_titles = {
      :people => 'People at this place',
      :sets => 'Sets at this place',
      :tags => 'Tags at this place',
      :places => 'Related Places'
    }

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
      params[:page] = @list.page_for_photo @me, params[:show], per_page_small
    end
    @photos = @list.get_photos @me, params[:page], per_page_small

    load_related_photos
    @related_dates = @list.get_all_dates

    @related_titles = {
      :people => 'People with this tag',
      :sets => 'Sets with this tag',
      :tags => 'Related Tags',
      :places => 'Places with this tag'
    }

    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

################################################################
## List of sets, tags, people

get '/:username/sets/?' do
  begin
    load_user params[:username]
    @sets = @user.get_sets @me, params[:page], 3*5
    @page = params[:page] || 1
    erb :sets
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/tags/?' do
  begin
    load_user params[:username]
    @tags = @user.get_popular_tags @me
    @max_photos = (@tags.to_a.max {|a,b| a.num <=> b.num}).num
    erb :tags
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/people/?' do
  begin
    load_user params[:username]
    @people = @user.get_people @me, params[:page], 3*5
    @page = params[:page] || 1
    erb :people
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

################################################################
## Dates

#get %r{/^([a-z]+)/([0-9]{4})/([0-9]{1,2})/([0-9]{1,2})} do |username, year, month, day|
get '/:username/:year/:month/:day/?' do |username, year, month, day|
  begin
    load_user username
    @list = @user
    date = DateTime.parse("#{year}-#{month}-#{day}").strftime "%B %e, %Y"
    @title = "Photos from #{date}"
    puts @title
    @photos = @user.get_photos_for_date @me, params[:page], per_page_small, year, month, day
    @photos = [] if !@photos

    if @photos.length > 0
      load_related_photos
      @related_dates = @list.get_related_dates year, month, day

      @related_titles = {
        :people => 'People in these photos',
        :sets => 'Sets in these photos',
        :tags => 'Tags in these photos',
        :places => 'Places in these photos'
      }
    end

    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/:year/:month/?' do |username, year, month|
#get %r{/^([a-z]+)/([0-9]{4})/([0-9]{1,2})} do |username, year, month|
  begin
    load_user username
    @list = @user
    date = DateTime.parse("#{year}-#{month}-01").strftime "%B %Y"
    @title = "Photos from #{date}"
    puts @title
    @photos = @user.get_photos_for_date @me, params[:page], per_page_small, year, month
    @photos = [] if !@photos

    if @photos.length > 0
      load_related_photos
      @related_dates = @list.get_related_dates year, month

      @related_titles = {
        :people => 'People in these photos',
        :sets => 'Sets in these photos',
        :tags => 'Tags in these photos',
        :places => 'Places in these photos'
      }
    end

    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

get '/:username/:year/?' do |username, year|
#get %r{/^([a-z]+)/([0-9]{4})} do |username, year|
  begin
    load_user username
    @list = @user
    @title = "Photos from #{year}"
    puts @title
    @photos = @user.get_photos_for_date @me, params[:page], per_page_small, year
    @photos = [] if !@photos

    if @photos.length > 0
      load_related_photos
      @related_dates = @list.get_related_dates year

      @related_titles = {
        :people => 'People in these photos',
        :sets => 'Sets in these photos',
        :tags => 'Tags in these photos',
        :places => 'Places in these photos'
      }
    end

    erb :'photos/list'
  rescue FlickrArchivr::Error => e
    erb :"#{e.erb_template}"
  end
end

################################################################
## Helper methods

def load_related_photos
  @photo_ids = @photos.collect {|p| p.id}
  @related_sets = Photoset.all(Photoset.photos.id => @photo_ids, :order => :num.desc)
  @related_tags = Tag.all(Tag.photos.id => @photo_ids, :order => :num.desc)
  @related_people = Person.all(Person.photos.id => @photo_ids, :order => :num.desc)
  @related_places = Place.all(Place.photos.id => @photo_ids, :order => :num.desc)
  # @related_sets = PhotoPhotoset.all(:photo_id => @photo_ids, :fields => [:photoset_id], :unique => true).to_a.reject{|a| a.photoset.nil?}.sort_by!{|a| -a.photoset.num}
  # @related_tags = PhotoTag.all(:photo_id => @photo_ids, :fields => [:tag_id], :unique => true).to_a.reject{|a| a.tag.nil?}.sort_by!{|a| -a.tag.num}
  # @related_people = PersonPhoto.all(:photo_id => @photo_ids, :fields => [:person_id], :unique => true).to_a.reject{|a| a.person.nil?}.sort_by! {|a| -a.person.num}
  # @related_places = PhotoPlace.all(:photo_id => @photo_ids, :fields => [:place_id], :unique => true).to_a.reject{|a| a.place.nil?}.sort_by! {|a| -a.place.num}
  true
end

def format_text(text) 
  text.gsub(/\n/, '<br />')
end

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
