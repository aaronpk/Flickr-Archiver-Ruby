Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'
Bundler.require
require File.join(File.expand_path(File.dirname(__FILE__)), 'helpers.rb')
Dir.glob(['lib', 'models'].map! {|d| File.join File.expand_path(File.dirname(__FILE__)), d, '*.rb'}).each {|f| require f}

puts "Starting in #{Sinatra::Base.environment} mode.."

class Controller < Sinatra::Base

  ##
  # Application specific configuration
  ##

  set :sessions,                 true
  set :session_secret,           'dfje2D44jJ'

  ##
  # The rest of this you shouldn't need to change (initially).
  ##

  set :raise_errors,    true
  set :show_exceptions, false
  set :method_override, true
  set :public,          'public'
  set :erubis,          :escape_html => true

  set :root, File.expand_path(File.join(File.dirname(__FILE__)))

  register Sinatra::Namespace
  register Sinatra::Flash

  configure do
    config_hash = YAML.load_file(File.join(root, 'config.yml'))[environment.to_s]
    GA_ID = config_hash['ga_id']
    FlickRaw.api_key = config_hash['flickr_consumer_key']
    FlickRaw.shared_secret = config_hash['flickr_consumer_secret']
    DataMapper.finalize
    DataMapper.setup :default, config_hash['database']
    # DataMapper.auto_upgrade!
    DataMapper::Model.raise_on_save_failure = true
  end

  configure :development do
    use Rack::CommonLogger
    Bundler.require :development
  end

  configure :test do
  end

  configure :production do
  end

  not_found do
    erubis :'404'
  end

  error do
    # Implement error reporting such as Airbrake (formerly Hoptoad) here.
    erubis :'500'
  end
end

require File.join('.', 'controller.rb')
