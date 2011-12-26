namespace '/photos' do
  get '/recent' do
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
  end
end

# namespace '/photo' do
#   get '/id' do
#     puts params[:id]
#     erb :'photos/recent'
#   end
# end