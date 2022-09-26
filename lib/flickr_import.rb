class FlickrImport

  def self.test(args)
    puts "Starting import for user: #{args.username}"
    @user = User.first :username => args.username

    @flickr = FlickRaw::Flickr.new
    @flickr.access_token = @user.access_token
    @flickr.access_secret = @user.access_secret

    mode = 'update'

    startTimestamp = @user.import_timestamp
    photosPerPage = 3

    if mode == 'import'
      photos = @flickr.people.getPhotos :user_id => "me", :per_page => photosPerPage, :max_upload_date => startTimestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    else
      photos = @flickr.photos.recentlyUpdated :min_date => startTimestamp, :per_page => photosPerPage, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    end

    totalPages = photos.pages
    puts "====== Found #{totalPages} pages"

    (0..totalPages).each do |page|
      puts "==== Beginning page #{page}"

      if page > 0
        if mode == 'import'
          photos = @flickr.people.getPhotos :user_id => "me", :page => page, :per_page => photosPerPage, :max_upload_date => startTimestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        else
          photos = @flickr.photos.recentlyUpdated :min_date => startTimestamp, :page => page, :per_page => photosPerPage, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        end
      end

      photos.each do |p|
        puts "#{p.title} #{p.dateupload}"
      end
      puts
    end

    puts "FINISHED!"
  end

  def self.update_counts(args)
    self.prepare_import args

    @user.people.each do |s|
      puts s.display_name
      s.update_count!
    end

    @user.photosets.each do |s|
      puts s.display_name
      s.update_count!
    end

    @user.tags.each do |s|
      puts s.display_name
      s.update_count!
    end

    @user.places.each do |s|
      puts s.display_name
      s.update_count!
    end
  end

  def self.do_import(args)
    self.process 'import', args
  end

  def self.do_update(args)
    self.process 'update', args
  end

  def self.process(mode, args)
    puts "Starting #{mode} for user: #{args.username}"
    self.prepare_import args

    if mode == 'import' && @user.import_timestamp == 0
      @user.import_timestamp = Time.now.to_i
      @user.save
    end

    startTimestamp = @user.import_timestamp
    updateStartedAt = DateTime.now
    photosPerPage = 100

    if mode == 'import'
      photos = @flickr.people.getPhotos :user_id => "me", :per_page => photosPerPage, :max_upload_date => startTimestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    else
      photos = @flickr.photos.recentlyUpdated :min_date => startTimestamp, :per_page => photosPerPage, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
    end

    totalPages = photos.pages
    puts "====== Found #{photos.total} photos in #{totalPages} pages"

    (1..totalPages).each do |page|
      puts
      puts "==== Beginning page #{page}"

      photos_added = 0

      if page > 1
        if mode == 'import'
          photos = @flickr.people.getPhotos :user_id => "me", :page => page, :per_page => photosPerPage, :max_upload_date => startTimestamp, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        else
          photos = @flickr.photos.recentlyUpdated :min_date => startTimestamp, :page => page, :per_page => photosPerPage, :extras => 'description,license,date_upload,date_taken,owner_name,original_format,last_update,geo,tags,machine_tags,o_dims,views,media,path_alias,url_sq,url_t,url_s,url_m,url_z,url_l,url_o'
        end
      end

      photos.each do |p|
        if photo = Photo.first(:flickr_id => p.id, :user => @user)
          puts "Photo #{p.id} already exists"
          next if mode == 'import'
        end

        photos_added += 1

        flickrPhoto = @flickr.photos.getInfo :photo_id => p.id, :secret => p.secret
        puts flickrPhoto.to_hash.to_json

        if photo.nil?
          previousSecret = nil
          # If an existing photo record was not found, prepare a new one
          photo = Photo.create_from_flickr flickrPhoto, @user
        else
          previousSecret = photo.secret
          # Else update the record from the flickr info
          photo.update_from_flickr flickrPhoto
        end

        # Determine whether to download files. During import, this is always. During updates,
        # only download if the secret has changed. The secret changing indicates that there is
        # a new jpg file (i.e. the photo was rotated or replaced)
        if mode == 'import'
          should_download = true
        else
          should_download = false
          should_download = true if previousSecret != photo.secret
          should_download = true if photo.path('sq')+photo.filename('sq') != photo.local_path_sq
        end

        if should_download
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

              new_local_path = photo.path(s)+photo.filename(s)

              # If the photo was renamed, delete the old file first
              old_local_path = photo.send("local_path_#{s}")
              if old_local_path && new_local_path != old_local_path
                old_abs_filename = SiteConfig.photo_root + old_local_path
                puts "! Deleting #{old_local_path}"
                `rm #{old_abs_filename}`
              end

              photo.send("local_path_#{s}=", new_local_path)

              # Download file from Flickr
              puts "Downloading #{flickrURL} to #{local_abs_filename}"
              `curl -o #{local_abs_filename} #{flickrURL}`
              puts "...done"
            end
          end # end each size

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
          end # end if video
        else
          puts "\twon't download file"
        end # end if should download

        owner = Person.first :nsid => flickrPhoto.owner.nsid, :user => @user
        if owner.nil?
          owner = Person.create_from_flickr flickrPhoto.owner, @user
        end
        photo.owner = owner

        # Tags
        if flickrPhoto.tags
          photoTags = @flickr.tags.getListPhoto :photo_id => p.id
          tag_ids = []
          photoTags.tags.tag.each do |photoTag|
            tag = Tag.first :tag => photoTag._content, :user => @user
            if tag.nil?
              tag = Tag.create_from_flickr photoTag, @user
            end
            photo.tags << tag
            tag.num = PhotoTag.count(:tag => tag) + 1
            tag.save
            tag_ids << tag.id
          end

          # Delete any relationships for tags that were removed
          if photo.id && tag_ids.length > 0
            photo.tags.each do |t|
              if !tag_ids.include?(t.id)
                puts "Tag '#{t.name}' was removed from the photo"
                photo.tags.delete(t)
              end
            end
          end
        end

        # Sets
        photoContexts = @flickr.photos.getAllContexts :photo_id => p.id
        if photoContexts && photoContexts.respond_to?('set')
          set_ids = []
          photoContexts.set.each do |photoSet|
            set = Photoset.first :flickr_id => photoSet.id, :user => @user
            if set.nil?
              set = Photoset.create_from_flickr photoSet, @user
            else
              set.update_from_flickr(photoSet)
            end
            photo.photosets << set
            set.save
            set.update_count!
            set_ids << set.id
          end

          # Delete any relationships for sets that were removed
          if photo.id && set_ids.length > 0
            photo.photosets.each do |s|
              if !set_ids.include?(s.id)
                puts "Set '#{s.title}' was removed from the photo"
                photo.photosets.delete(s)
              end
            end
          end
        end

        # People
        if flickrPhoto.respond_to?('people') && flickrPhoto.people.respond_to?('haspeople') && flickrPhoto.people.haspeople
          photoPeople = @flickr.photos.people.getList :photo_id => p.id
          people_ids = []
          photoPeople.person.each do |photoPerson|
            person = Person.first :nsid => photoPerson.nsid, :user => @user
            puts photoPerson.to_hash
            if person.nil?
              person = Person.create_from_flickr photoPerson, @user
            end
            person.save
            people_ids << person.id
            if photoPerson.respond_to?('w')
              PersonPhoto.first_or_create({:person => person, :photo => photo}, {:w => photoPerson.w, :h => photoPerson.h, :x => photoPerson.x, :y => photoPerson.y})
            else
              PersonPhoto.first_or_create :person => person, :photo => photo
            end
            person.update_count!
          end

          # Delete any relationships for people that were removed
          if photo.id && people_ids.length > 0
            photo.people.each do |s|
              if !people_ids.include?(s.id)
                puts "Person '#{s.username}' was removed from the photo"
                photo.people.delete(s)
              end
            end
          end
        end
        if flickrPhoto.respond_to?('people') && flickrPhoto.people.respond_to?('haspeople') && flickrPhoto.people.haspeople == 0
            photo.people.each do |s|
              puts "Person '#{s.username}' was removed"
              photo.people.delete(s)
            end
        end

        # Places
        begin
          photoPlaces = @flickr.photos.geo.getLocation :photo_id => p.id
          if photoPlaces && photoPlaces.respond_to?('location')
            location = photoPlaces.location

            geoPerms = @flickr.photos.geo.getPerms :photo_id => p.id
            photo.geo_public  = geoPerms.ispublic
            photo.geo_friend  = geoPerms.isfriend
            photo.geo_family  = geoPerms.isfamily
            photo.geo_contact = geoPerms.iscontact

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
                place.save
                place.update_count!
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
        if mode == 'import'
          @user.import_timestamp = photo.date_uploaded.to_time.to_i
          @user.last_photo_imported = p.id
          @user.save
        end

      end   # for each photos

    end

    if mode == 'update'
      @user.import_timestamp = updateStartedAt.to_time.to_i
      @user.save
    end

    puts "FINISHED!!"

  end   # process

  def self.import_sets(args)
    puts "Starting set import for user: #{args.username}"
    self.prepare_import args

    flickrSets = @flickr.photosets.getList :page => 1, :per_page => 100

    totalPages = flickrSets.pages
    puts "====== Found #{flickrSets.total} sets in #{totalPages} pages"

    sequence = 0
    set_ids = []

    # TODO: Figure out how to tell if a set is public or private by searching the photos inside the sets.

    (1..totalPages).each do |page|
      puts
      puts "==== Beginning page #{page}"

      if page > 1
        flickrSets = @flickr.photosets.getList :page => page, :per_page => 100
      end

      flickrSets.each do |photoSet|
        puts "---- #{photoSet.title}"

        set_ids << photoSet.id

        set = Photoset.first :flickr_id => photoSet.id, :user => @user
        if set.nil?
          set = Photoset.create_from_flickr photoSet, @user
        else
          set.update_from_flickr(photoSet)
        end

        set.sequence = sequence
        sequence += 1

        set.is_public = (set.count_public_photos == 0 ? false : true)

        set.save()
      end
    end

    puts "Done importing new sets. Now looking for deleted sets..."

    # Loop through all sets in the DB. If there are any that are not in the list of set_ids just seen, delete them.

    if set_ids.length > 0
      @user.photosets.each do |photoset|
        if !set_ids.include?(photoset.flickr_id)
          puts "\tSet '#{photoset.title}' was deleted"
          photoset.destroy
        end
      end
    else
      puts "Looks like there was an error retrieving sets. Won't delete anything this time."
    end

    puts "Finished!!"
  end

  def self.prepare_import(args)
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
  end

end
