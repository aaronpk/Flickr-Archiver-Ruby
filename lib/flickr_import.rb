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

    photos = @flickr.people.getPhotos :user_id => "me", :per_page => 103, :max_upload_date => @user.import_timestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
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
          flickrURL = p.send('url_'+s)

          # Store the original flickr URLs
          photo.send('url_'+s+'=', flickrURL)
          photo.send('width_'+s+'=', p.send('width_'+s))
          photo.send('height_'+s+'=', p.send('height_'+s))

          # Make the parent folder
          FileUtils.mkdir_p(photo.abs_path(s))
          local_abs_filename = photo.abs_filename(s)

          # Download file from Flickr
          puts "Downloading #{flickrURL} to #{local_abs_filename}"
          `curl -o #{local_abs_filename} #{flickrURL}`
          puts "...done"

          photo.local_path = photo.path("%") + photo.filename("%")
        end
      end

      owner = Person.first :nsid => flickrPhoto.owner.nsid, :user => @user
      if owner.nil?
        owner = Person.create_from_flickr flickrPhoto.owner, @user
      end
      photo.owner = owner

      # Tags
      if flickrPhoto.tags
        photoTags = @flickr.tags.getListPhoto :photo_id => p.id
        photoTags.tags.tag.each do |photoTag|
          tag = Tag.first :tag => photoTag._content, :user => @user
          if tag.nil?
            tag = Tag.create_from_flickr photoTag, @user
          end
          photo.tags << tag
          tag.num = Photos.count(:tag => tag)
          tag.save
        end
      end

      # Sets
      photoContexts = @flickr.photos.getAllContexts :photo_id => p.id
      if photoContexts && photoContexts.respond_to?('set')
        photoContexts.set.each do |photoSet|
          set = Photoset.first :flickr_id => photoSet.id, :user => @user
          if set.nil?
            set = Photoset.create_from_flickr photoSet, @user
          end
          photo.photosets << set
          set.num = Photos.count(:photoset => set)
          set.save
        end
      end

      # People
      if flickrPhoto.respond_to?('people') && flickrPhoto.people.respond_to?('haspeople') && flickrPhoto.people.haspeople
        photoPeople = @flickr.photos.people.getList :photo_id => p.id
        photoPeople.person.each do |photoPerson|
          person = Person.first :nsid => photoPerson.nsid, :user => @user
          puts photoPerson.to_hash
          if person.nil?
            person = Person.create_from_flickr photoPerson, @user
          end
          if photoPerson.respond_to?('w')
            PersonPhoto.create :person => person, :photo => photo, :w => photoPerson.w, :h => photoPerson.h, :x => photoPerson.x, :y => photoPerson.y
          else
            PersonPhoto.create :person => person, :photo => photo
          end
        end
      end

      # Places
      photoPlaces = @flickr.photos.geo.getLocation :photo_id => p.id
      if photoPlaces && photoPlaces.respond_to?('place')
        photoPlaces.place.each do |photoPlace|
          place = Place.first :flickr_id => photoPlace.id, :user => @user
          if place.nil?
            place = Place.create_from_flickr photoPlace, @user
          end
          photo.places << place
          place.num = Photos.count(:place => place)
          place.save
        end
      end

      # Save the photo in the database
      photo.save

      # Update the user record to reflect the timestamp of the last photo downloaded
      @user.import_timestamp = photo.date_uploaded.to_time.to_i
      @user.save

    end
  end

end