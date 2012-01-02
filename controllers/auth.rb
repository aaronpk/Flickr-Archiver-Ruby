  get '/auth/signout' do
    session[:access_token] = nil
    session[:access_token_secret] = nil
    session[:user_id] = nil
    redirect '/'
  end

  get '/auth/flickr' do
    # Send to the Flickr auth URL
    session[:access_token] = nil
    session[:access_token_secret] = nil
    session[:user_id] = nil
    token = @flickr.get_request_token({:oauth_callback => "#{request.url_without_path}/auth/flickr/callback"})
    auth_url = @flickr.get_authorize_url(token['oauth_token'], :perms => 'read')
    session[:request_token] = token['oauth_token']
    session[:request_token_secret] = token['oauth_token_secret']
    redirect auth_url
  end
  
  get '/auth/flickr/callback' do
    puts "Redirect from Flickr"
    puts params
    begin
      @flickr.get_access_token(session[:request_token], session[:request_token_secret], params[:oauth_verifier])
      login = @flickr.test.login
      puts "You are now authenticated as #{login.username} with token #{@flickr.access_token} and secret #{@flickr.access_secret}"
      session[:access_token] = @flickr.access_token
      session[:access_token_secret] = @flickr.access_secret
      session[:request_token] = nil
      session[:request_token_secret] = nil

      # Retrieve the user or create a new user account
      user = User.first :username => login.username
      if user.nil?
        user = User.new :username => login.username, :nsid => login.id, :access_token => @flickr.access_token, :access_secret => @flickr.access_secret
        user.save
      end
      session[:user_id] = user.id

      redirect '/' + user.username
    rescue FlickRaw::FailedResponse => e
      puts "Authentication Failed : #{e.msg}"
      redirect '/auth/flickr/error'
    end
  end

  get '/auth/flickr/error' do
    session[:user_id] = nil
    session[:access_token] = nil
    erb :error
  end

