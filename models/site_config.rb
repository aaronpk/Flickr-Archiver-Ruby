module FlickrArchivr
  class SiteConfig < Hashie::Mash
    def key; self['key'] end
  end
end