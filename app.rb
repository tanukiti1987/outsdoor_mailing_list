class App < Sinatra::Base
  register Sinatra::Reloader

  helpers do
    def mg_client
      @mg_client ||= Mailgun::Client.new ENV['MAILGUN_API_KEY']
    end

    # for validate email address
    # see: https://documentation.mailgun.com/api-email-validation.html#email-validation
    def public_mg_client
      @public_mg_client ||= Mailgun::Client.new ENV['PUBLIC_MAILGUN_API_KEY']
    end

    def valid_address?(address)
      public_mg_client.get("address/validate", address: address).to_h["is_valid"]
    end

    def send_receipt_mail(address:, type:)
      subject, message = '', ''
      case type
      when :subscribe
        subject = '[outdoor] アウトドアサークル同窓会メーリングリストのメンバーになりました'
        message = erb :receipt_subscribe
      when :unsubscribe
        subject = '[outdoor] アウトドアサークル同窓会メーリングリストのメンバーからはずれました'
        message = erb :receipt_unsubscribe
      else
        return
      end

      message_params =  { from: no_reply_address,
                          to: address,
                          subject: subject,
                          text: message,
                        }

      mg_client.send_message domain, message_params
    end

    def mailing_list_address
      "reunion@#{domain}"
    end

    def no_reply_address
      "no-reply@#{domain}"
    end

    def domain
      'outsdoor.club'
    end
  end

  before %r{^/(|un)subscribe$} do
    if params['email'].nil? || !valid_address?(params['email'])
      redirect to('/invalid_address')
    end
  end

  get '/robot.txt' do
    erb :"robot.txt"
  end

  get '/' do
    haml :index
  end

  get '/invalid_address' do
    haml :invalid_address
  end

  get '/unexpected_error' do
    haml :unexpected_error
  end

  get '/already_subscribed' do
    haml :already_subscribed
  end

  get '/subscribed' do
    haml :subscribed
  end

  post '/subscribe' do
    begin
      response = mg_client.get("lists/#{mailing_list_address}/members/#{params['email']}").to_h
      if response.to_h.dig("member", "subscribed")
        redirect to('/already_subscribed')
      else
        mg_client.put("lists/#{mailing_list_address}/members/#{params['email']}", { subscribed: true })
        send_receipt_mail(address: params['email'], type: :subscribe)
        redirect to('/subscribed')
      end
    rescue Mailgun::CommunicationError => e
      mg_client.post(
        "lists/#{mailing_list_address}/members",
        { subscribed: true, address: params['email'], vars: { created_at: Time.now }.to_json
      })
      send_receipt_mail(address: params['email'], type: :subscribe)
      redirect to('/subscribed')
    rescue => e
      redirect to('/unexpected_error')
    end
  end

  get '/unsubscribed' do
    haml :unsubscribed
  end

  get '/not_a_member' do
    haml :not_a_member
  end

  post '/unsubscribe' do
    begin
      response = mg_client.get("lists/#{mailing_list_address}/members/#{params['email']}").to_h
      if response.to_h.dig("member", "subscribed")
        mg_client.put("lists/#{mailing_list_address}/members/#{params['email']}", { subscribed: false })
        send_receipt_mail(address: params['email'], type: :unsubscribe)
        redirect to('/unsubscribed')
      else
        redirect to('/not_a_member')
      end
    rescue Mailgun::CommunicationError => e
      redirect to('/not_a_member')
    rescue => e
      redirect to('/unexpected_error')
    end
  end
end
