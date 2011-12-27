class FlickrImport

  def self.do_import(args)
    puts "Starting import for user: #{args.username}"
    @user = User.first :username => args.username

    if @user.nil?
      puts "ERROR: No user '#{args.username}'"
      exit!
    end

    if @user.access_token.nil?
      puts "ERROR: No Flickr tokens for user #{args.username}"
      exit!
    end

    @flickr = FlickRaw::Flickr.new
    @flickr.access_token = @user.access_token
    @flickr.access_secret = @user.access_secret

    begin
      login = @flickr.test.login
      puts "Flickr auth test passed #{login.username}"
    rescue FlickRaw::FailedResponse => e
      puts "ERROR: Flickr authentication failed : #{e.msg}"
      exit!
    end

    if @user.import_timestamp == 0
      @user.import_timestamp = Time.now.to_i
      @user.save
    end

    # Begin downloading one page of photos starting at the last timestamp

    photos = @flickr.people.getPhotos :user_id => "me", :per_page => 500, :max_upload_date => @user.import_timestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    #photos = @flickr.people.getPhotos :min_upload_date => "2011-12-13", :user_id => "me", :per_page => 1, :max_upload_date => "2011-12-14", :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    photos.each do |p|
      if Photo.first :flickr_id => p.id, :user => @user
        puts "Photo #{p.id} already exists"
        next
      end
      flickrPhoto = @flickr.photos.getInfo :photo_id => p.id, :secret => p.secret
      puts flickrPhoto.to_hash.to_json
      photo = Photo.create_from_flickr flickrPhoto, @user
      photo.url = FlickRaw.url_photopage(flickrPhoto)
      Photo.sizes.each do |s|
        if p.respond_to?('url_'+s)
          photo.send('url_'+s+'=', p.send('url_'+s))
          photo.send('width_'+s+'=', p.send('width_'+s))
          photo.send('height_'+s+'=', p.send('height_'+s))
        end
      end
      if flickrPhoto.tags
        photoTags = @flickr.tags.getListPhoto :photo_id => p.id
        # puts photoTags.to_hash
        photoTags.tags.tag.each do |photoTag|
          tag = Tag.first :tag => photoTag._content, :user => @user
          if tag.nil?
            tag = Tag.create_from_flickr photoTag, @user
          end
          photo.tags << tag
        end
      end
      photoContexts = @flickr.photos.getAllContexts :photo_id => p.id

      if photoContexts && photoContexts.respond_to?('set')
        photoContexts.set.each do |photoSet|
          set = Set.first :flickr_id => photoSet.id
          if set.nil?
            set = Set.create_from_flickr photoSet, @user
          end
          photo.sets << set
        end
      end

      photo.save
    end
  end

end