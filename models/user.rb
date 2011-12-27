class User
  include DataMapper::Resource
  property :id, Serial

  property :nsid, String, :length => 50, :index => true
  property :username, String, :length => 100

  property :import_timestamp, Integer, :default => 0

  property :access_token, String, :length => 255
  property :access_secret, String, :length => 255

  property :created_at, DateTime
  property :updated_at, DateTime
end