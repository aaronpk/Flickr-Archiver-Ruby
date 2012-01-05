before do
  begin
    @flickr = FlickRaw::Flickr.new

    unless session[:access_token].nil?
      # puts "Already have an access token: #{session[:access_token]}"
      @flickr.access_token = session[:access_token]
      @flickr.access_secret = session[:access_token_secret]
    end
  rescue SocketError => e
    @flickr = nil
  end

  if session[:user_id]
    @me = User.get session[:user_id]
  else
    @me = nil
  end
end

get '/?' do
  if @me
    redirect "/#{@me.username}"
  else
    erb :index
  end
end

get '/about/?' do
  erb :about
end

get '/:username/search' do
  erb :search
end

post '/:username/search' do
  #@search_sets = Photoset.all(:user_id => @user.id, )
  erb :search
end
