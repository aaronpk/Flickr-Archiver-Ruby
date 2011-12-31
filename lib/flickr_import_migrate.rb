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
end