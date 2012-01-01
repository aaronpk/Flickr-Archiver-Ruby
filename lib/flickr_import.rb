class FlickrImport

  def self.test(args)
    puts "Starting import for user: #{args.username}"
    @user = User.first :username => args.username

    @flickr = FlickRaw::Flickr.new
    @flickr.access_token = @user.access_token
    @flickr.access_secret = @user.access_secret

    while true
      photos = @flickr.people.getPhotos :user_id => "me", :per_page => 100, :max_upload_date => @user.import_timestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
      photos.each do |p|
        puts "#{p.title} #{p.dateupload}"

        @user.import_timestamp = p.dateupload
        @user.save
      end
      break if photos.length == 0
    end

    puts "FINISHED!"
  end

  def self.do_import(args)
    self.process 'import', args
  end

  def self.do_update(args)
    self.process 'update', args
  end

  def self.process(mode, args)
    puts "Starting #{mode} for user: #{args.username}"
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

    if mode == 'import' && @user.import_timestamp == 0
      @user.import_timestamp = Time.now.to_i
      @user.save
    end

    while true
      photos_added = 0

      if mode == 'import'
        # Begin downloading one page of photos starting at the last timestamp
        photos = @flickr.people.getPhotos :user_id => "me", :per_page => 100, :max_upload_date => @user.import_timestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        #photos = @flickr.people.getPhotos :user_id => "me", :per_page => 1, :max_upload_date => 1324398709, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        #photos = @flickr.people.getPhotos :min_upload_date => "2011-12-13", :user_id => "me", :per_page => 1, :max_upload_date => "2011-12-14", :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
      else
        # Flickr limits the recentlyUpdated feed to at most 500 at a time
        photos = @flickr.photos.recentlyUpdated :min_date => @user.import_timestamp, :per_page => 3, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        # For 'update' mode, we want to iterate through photos oldest to newest, but flickr returns them in descending order
        photos = photos.to_a.reverse
      end

      photos.each do |p|
        if photo = Photo.first(:flickr_id => p.id, :user => @user)
          puts "Photo #{p.id} already exists"
          next if mode == 'import'
          next if @user.import_timestamp == p.lastupdate.to_i
        end

        photos_added += 1

        flickrPhoto = @flickr.photos.getInfo :photo_id => p.id, :secret => p.secret
        puts flickrPhoto.to_hash.to_json

        if photo.nil?   # If an existing photo record was not found, prepare a new one
          photo = Photo.create_from_flickr flickrPhoto, @user
        else
          photo.update_from_flickr flickrPhoto
        end

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

            local_path = photo.path(s)+photo.filename(s)

            # If the photo was renamed, delete the old file first
            if local_path != photo.send("local_path_#{s}")
              old_abs_filename = photo.send("local_path_#{s}")
              puts "! Deleting #{old_abs_filename}"
              `rm #{local_abs_filename}`
            end

            photo.send("local_path_#{s}=", local_path)

            # Download file from Flickr
            puts "Downloading #{flickrURL} to #{local_abs_filename}"
            `curl -o #{local_abs_filename} #{flickrURL}`
            puts "...done"
          end
        end

        # If it's a video, download the file
        if flickrPhoto.media == "video"
          FileUtils.mkdir_p(photo.abs_path('v'))
          local_abs_filename = photo.abs_filename('v')

          # The secret seems to be different for the original version of the video. Not sure how to find it
          # videoURL = "http://www.flickr.com/photos/#{@user.nsid}/#{photo.flickr_id}/play/orig/#{photo.secret}/"

          # Instead, iterate through all the available sizes and look for the largest available
          flickrSizes = @flickr.photos.getSizes :photo_id => p.id
          largestSize = 0
          videoURL = ''
          flickrSizes.size.each do |sz|
            if sz.media == "video"
              if sz.width.to_i > largestSize
                largestSize = sz.width.to_i
                videoURL = sz.source
              end
            end
          end

          puts "Downloading #{videoURL} to #{local_abs_filename}"
          `curl -L -o #{local_abs_filename} #{videoURL}`
          puts "...done"

          photo.local_path_v = photo.filename('v')
          photo.media = "video"
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
            tag.num = PhotoTag.count(:tag => tag) + 1
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
            set.num = PhotoPhotoset.count(:photoset => set) + 1
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
              PersonPhoto.first_or_create({:person => person, :photo => photo}, {:w => photoPerson.w, :h => photoPerson.h, :x => photoPerson.x, :y => photoPerson.y})
            else
              PersonPhoto.first_or_create :person => person, :photo => photo
            end
          end
        end

        # Places
        begin
          photoPlaces = @flickr.photos.geo.getLocation :photo_id => p.id
          if photoPlaces && photoPlaces.respond_to?('location')
            location = photoPlaces.location
            if location.respond_to?('latitude')
              photo.latitude = location.latitude
              photo.longitude = location.longitude
              photo.accuracy = location.accuracy
            end

            ['neighbourhood','locality','county','region','country'].each do |type|
              if location.respond_to? type
                puts location.send(type)._content
                place = Place.first :type => type, :flickr_id => location.send(type).place_id, :user => @user
                if place.nil?
                  place = Place.create_from_flickr type, location.send(type), @user
                end
                photo.places << place
                place.num = PhotoPlace.count(:place => place) + 1
                place.save
              end
            end
          end
        rescue FlickRaw::FailedResponse
          # 'flickr.photos.geo.getLocation' - Photo has no location information
        end

        # Save the photo in the database
        photo.save

        # Update the user record to reflect the timestamp of the last photo downloaded.
        # In 'import' mode, this relies on the photos being returned in descending order.
        # In 'update' mode, this relies on the photos being looped through in ascending order.
        if mode == 'import'
          @user.import_timestamp = photo.date_uploaded.to_time.to_i
        else
          @user.import_timestamp = p.lastupdate.to_i
        end
        @user.last_photo_imported = p.id
        @user.save

      end   # for each photos

      # Stop looking for photos when we reach the end (first date) of the photo stream
      break if photos.length == 0 || photos_added == 0

    end

    puts "FINISHED!!"

  end   # do_import

end