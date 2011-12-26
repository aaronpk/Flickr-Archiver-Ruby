class Sinatra::Base
  helpers do
    def h(text); Rack::Utils.escape_html text end
    def partial(page, options={})
      erb page, options.merge!(:layout => false)
    end
  end
end