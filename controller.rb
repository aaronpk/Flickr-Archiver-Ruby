class Controller < Sinatra::Base

  before do
    @flickr = flickr = FlickRaw::Flickr.new

    unless session[:access_token].nil?
      @flickr.access_token = session[:access_token]
      @flickr.access_secret = session[:access_token_secret]
    end
  end

  get '/' do
    erubis :index
  end
  
  get '/auth/flickr' do
    # Send to the Flickr auth URL
    session[:access_token] = nil
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
      puts "You are now authenticated as #{login.username}"
      session[:access_token] = @flickr.access_token
      session[:access_token_secret] = @flickr.access_secret
      redirect '/dashboard'
    rescue FlickRaw::FailedResponse => e
      puts "Authentication Failed : #{e.msg}"
      redirect '/'
    end
  end
  
get '/me' do
  login = @flickr.test.login
  puts "You are authenticated as #{login.username}"
  login.username
end

end
