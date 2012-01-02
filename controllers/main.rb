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
  erb :index
end

get '/:username/search' do
  erb :search
end

post '/:username/search' do 
  erb :search
end

get '/me' do
  puts "##############"
  puts session
  puts @me
  puts "##############"
  # begin
  #   login = @flickr.test.login
  #   puts "You are authenticated as #{login.username}"
  #   @username = login.username
  #   erb :me
  # rescue FlickRaw::FailedResponse => e
  #   puts "Authentication Failed : #{e.msg}"
  #   redirect '/'
  # end
end
