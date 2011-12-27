module FlickrArchivr
  class Error < Exception

  end
  class NotFoundError < Error
    def erb_template
      "error/404"
    end
  end
  class ForbiddenError < Error
    def erb_template
      "error/403"
    end
  end
end