class App < Sinatra::Base
  register Sinatra::Reloader

  get '/' do
    haml :index
  end

  get '/mail' do
    mg_client = Mailgun::Client.new ENV['MAILGUN_API_KEY']

    # Define your message parameters
    message_params =  { from: 'no-reply@outsdoor.club',
                        to:   'example@example.com',
                        subject: 'The Ruby SDK is awesome!',
                        text:    'It is really easy to send a message!'
                      }

    # Send your message through the client
    mg_client.send_message 'outsdoor.club', message_params
  end

  get %r{^/(stylesheets|javascripts)/(.*)\.(css|js)$} do
    dir = params[:captures][0]
    file = params[:captures][1]
    method = params[:captures][2] == 'css' ? :scss : :coffee
    send(method, :"assets/#{dir}/#{file}")
  end
end
