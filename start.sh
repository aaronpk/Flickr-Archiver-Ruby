
if [ $# -eq 0 ] ; then
  echo Starting in development mode...
  bundle exec shotgun -P public -p 3000
  exit 0
fi

if [ $1 == 'production' ] ; then
  echo Starting in production mode...
  bundle exec rackup
  exit 0
fi

echo Usage: $0 production
exit 1

