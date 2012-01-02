def init(env=ENV['RACK_ENV']); end
require File.join('.', 'environment.rb')

namespace :db do
  task :bootstrap do
    init
    DataMapper.auto_migrate!
  end
  task :migrate do
    init
    DataMapper.auto_upgrade!
  end
end

namespace :flickr do

  task :import, :username do |t, username|
    init
    FlickrImport.do_import username
  end

  task :update, :username do |t, username|
    FlickrImport.do_update username
  end

  task :sets, :username do |t, username|
    FlickrImport.import_sets username
  end


  # Migration scripts. No longer needed

  task :add_local_path do
    FlickrImportMigrate.add_local_path
  end

  task :secrify do
    FlickrImportMigrate.secrify
  end

  task :test, :username do |t, username|
    init
    FlickrImport.test username
  end
end
