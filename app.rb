class App < Sinatra::Base
  register Sinatra::Reloader

  get '/' do
    haml :index
  end

  get %r{^/(stylesheets|javascripts)/(.*)\.(css|js)$} do
    dir = params[:captures][0]
    file = params[:captures][1]
    method = params[:captures][2] == 'css' ? :scss : :coffee
    send(method, :"assets/#{dir}/#{file}")
  end
end
