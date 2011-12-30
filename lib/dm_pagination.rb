
module DataMapper
  module Pagination

    def page page = nil, options = {}
      options, page = page, nil if page.is_a? Hash
      page_param  = pager_option(:page_param, options)
      page ||= pager_option page_param, options
      options.delete page_param
      page = 1 unless (page = page.to_i) && page > 1
      per_page    = pager_option(:per_page, options).to_i
      query = options.dup
      collection = new_collection scoped_query(options = {
        :limit => per_page,
        :offset => (page - 1) * per_page,
        #:order => [:id.desc]
      }.merge(query))
      #query.delete :order
      options.merge! :total => count(query), page_param => page, :page_param => page_param
      collection.pager = DataMapper::Pager.new options
      collection
    end

  end
end