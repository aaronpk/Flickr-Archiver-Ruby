Flickr Archivr
==============

This project is meant to back up a single user's Flickr photo stream. It can also serve as a public web mirror of the user's Flickr
photos and sets.


Installation
------------

1) Install Bundler:

    $ gem install bundler

2) Clone the project:

    $ git clone git@github.com:aaronpk/Flickr-Archivr.git

3) Create a Flickr app: http://www.flickr.com/services/apps/create/

4) Edit config.yml to include your Flickr consumer key and secret

5) Install dependancies with Bundler:

    $ bundle install

6) Start the server:

    For development:
    $ bundle exec rackup -s thin

    For development, app reloads automatically:
    $ bundle exec shotgun -s thin -P public

    For production:
    $ bundle exec thin start -e production
    Look at the documentation for thin's command line. You can configure for multiple workers, etc..

That's it! Visit http://localhost:9292/ and sign in with your Flickr account!

