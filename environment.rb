Encoding.default_internal = 'UTF-8'
require 'rubygems'
require 'bundler/setup'
Bundler.require
require File.join(File.expand_path(File.dirname(__FILE__)), 'helpers.rb')
Dir.glob(['lib', 'models'].map! {|d| File.join File.expand_path(File.dirname(__FILE__)), d, '*.rb'}).each {|f| require f}

SiteConfig = FlickrArchivr::SiteConfig.new YAML.load_file('config.yml')[Sinatra::Base.environment.to_s] if File.exists?('config.yml')

puts "Starting in #{Sinatra::Base.environment} mode.."

helpers Sinatra::UserAgentHelpers

set :raise_errors,    true
set :show_exceptions, false
set :method_override, true
set :public_folder,   'public'

use Rack::Session::Cookie, :key => 'website',
                           :path => '/',
                           :expire_after => 2592000,
                           :secret => 'YQjEEqd8'

configure do
  FlickRaw.api_key = SiteConfig.flickr_consumer_key
  FlickRaw.shared_secret = SiteConfig.flickr_consumer_secret
  DataMapper.finalize
  DataMapper.setup :default, SiteConfig.database
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
  erb :'404'
end

error do
  # Implement error reporting such as Airbrake here.
  erb :'500'
end

Dir.glob(['controllers/**'].map! {|d| File.join d, '*.rb'}).each {|f| require_relative f}
