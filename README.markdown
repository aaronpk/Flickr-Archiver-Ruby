Flickr Archiver
===============

UNMAINTAINED: I am leaving this project here for historical purposes. Since it was originally written in 2012, there are a lot of changes needed to get it working again today. I am also personally not using Flickr as my primary photo archive anymore, so I don't need the main features this project provides which is continually syncing a copy of a Flickr account. Please check out my new project, [Flickr Archivr](https://github.com/aaronpk/Flickr-Archivr), which archives an entire Flickr account to a static website.

---

This project is meant to back up a single user's Flickr photo stream. It can also serve as a public web mirror of the user's Flickr
photos and sets.

![Flickr Archiver Screenshot](images/flickr-archivr-photostream.png "Flickr Archivr Screenshot")

![Flickr Archiver Screenshot](images/flickr-archivr-one-photo.png "Flickr Archivr Screenshot")


Installation
------------

1) Clone the project:

    $ git clone git@github.com:aaronpk/Flickr-Archiver.git

2) Install Bundler:

    $ gem install bundler

3) Create a Flickr app: http://www.flickr.com/services/apps/create/

4) Create a mysql database for your photo archive.

5) Copy config.yml.template to config.yml. Edit it to include your Flickr
   consumer key and secret, database connection details, and to set the folder where you want to store the
   downloaded images. This should be in the "public" directory if you want
   them served automatically by the application's web server.

6) Install dependancies with Bundler:

    $ bundle install

7) Setup the database:

    $ rake db:bootstrap

8) Start the server:

    For development:
    $ bundle exec rackup -s thin

    For development, app reloads automatically:
    $ bundle exec shotgun -s thin -P public

    For production:
    $ bundle exec thin start -e production
    Look at the documentation for thin's command line. You can configure for multiple workers, etc..

That's it! Visit http://localhost:3000/ and sign in with your Flickr account!


Initial Import
--------------

After signing in and connecting your Flickr account, you can do the initial import of your photo stream. This
is done with a rake task:

    $ rake flickr:import[username]

After this finishes, you should have a complete archive of your Flickr stream. Visit http://localhost:3030/username and you
should see everything there.

If this errored out you can safely restart it and it will continue where it left off. This is accomplished by using the
`import_timestamp` field on the `users` table. After this has finished successfully, you should update the field to the
timestamp of the most recent photo in your stream. You can do this with the following SQL command:

    UPDATE users SET import_timestamp = (SELECT UNIX_TIMESTAMP(MAX(date_uploaded)) FROM photos WHERE user_id = 1) WHERE id = 1


Keeping Updated
---------------

From here on out, you will only need to download new photos and photos that have been modified. Luckily Flickr provides a nice
API method for retrieving recently modified photos, which they say includes changes to the title, description, tags, or "just
modified somehow :-)"

    $ rake flickr:update[username]

Any changes to photos will cause them to be re-imported using this task! You can run this every 5 minutes, hour, day, or whatever.
If you rename photos, the filename on disk will have changed, so the script will remove the old filename and re-download the photo.

