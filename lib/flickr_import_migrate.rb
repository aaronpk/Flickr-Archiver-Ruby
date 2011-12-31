class FlickrImportMigrate
  def self.add_local_path
    Photo.all.each do |p|
      puts p.id
      Photo.sizes.each do |s|
        if p.send("url_#{s}")
          puts p.path(s)+p.filename(s)
          p.send("local_path_#{s}=", p.path(s)+p.filename(s))
        else
          puts "Missing size #{s}"
        end
      end
      if p.media == 'video'
        p.local_path_v = p.path('v')+p.filename('v')
        puts p.path('v')+p.filename('v')
      end
      p.save()
    end
  end

  def self.secrify
    Photo.all.each do |p|
      json = JSON.parse p.raw
      p.original_secret = json['originalsecret']
      p.format = json['originalformat']
      Photo.sizes.each do |s|
        if (path = p.send("local_path_#{s}"))
          if path != p.path(s)+p.filename(s)
            old_path = SiteConfig.photo_root + path
            new_path = SiteConfig.photo_root + p.path(s)+p.filename(s)
            p.send("local_path_#{s}=", p.path(s)+p.filename(s))
            puts p.path(s)+p.filename(s)
            `mv #{old_path} #{new_path}`
          end
        end
      end
      if p.media == 'video'
        old_path = SiteConfig.photo_root + p.local_path_v
        new_path = SiteConfig.photo_root + p.path('v')+p.filename('v')
        p.local_path_v = p.path('v')+p.filename('v')
        puts p.path('v')+p.filename('v')
        `mv #{old_path} #{new_path}`
      end
      p.save()
    end
  end
end