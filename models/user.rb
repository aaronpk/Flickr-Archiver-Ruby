class User
  include DataMapper::Resource
  property :id, Serial

  property :username, String, :length => 100

  property :access_token, String, :length => 255
  property :access_secret, String, :length => 255
end