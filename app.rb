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

    def send_confirmation_mail(address:, type:)
      subject, message = '', ''
      case type
      when :subscribe
        from = "subscribe_confirm@#{domain}"
        subject = '【要返信】アウトドアサークル同窓会メーリングリストのメンバー登録確認'
        message = erb :subscribe_confirm
      when :unsubscribe
        from = "unsubscribe_confirm@#{domain}"
        subject = '【要返信】アウトドアサークル同窓会メーリングリストのメンバー登録確認'
        message = erb :unsubscribe_confirm
      else
        return
      end

      send_mail(from: from, to: address, subject: subject, text: message)
    end

    def send_completed_mail(address:, type:)
      subject, message = '', ''
      case type
      when :subscribed
        subject = '[outdoor] アウトドアサークル同窓会メーリングリストのメンバーになりました'
        message = erb :subscribed_receipt
      when :unsubscribed
        subject = '[outdoor] アウトドアサークル同窓会メーリングリストのメンバーからはずれました'
        message = erb :unsubscribed_receipt
      else
        return
      end
      send_mail(from: no_reply_address, to: address, subject: subject, text: message)
    end

    def send_mail(from:, to:, subject:, text:)
      message_params =  { from: from,
                          to: to,
                          subject: subject,
                          text: text,
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

  before %r{^/(|un)subscribe_confirm$} do
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

  post '/subscribe' do
    address = params['sender']
    name = params['from']

    begin
      response = mg_client.get("lists/#{mailing_list_address}/members/#{address}").to_h
      unless response.to_h.dig("member", "subscribed")
        mg_client.put("lists/#{mailing_list_address}/members/#{address}", { subscribed: true, name: name })
        send_completed_mail(address: address, type: :subscribed)
      end
    rescue Mailgun::CommunicationError => e
      mg_client.post(
        "lists/#{mailing_list_address}/members",
        { subscribed: true, address: address, name: name, vars: { created_at: Time.now }.to_json
      })
      send_completed_mail(address: address, type: :subscribed)
    rescue => e
      send_mail(
        from: no_reply_address,
        to: ENV['ADMIN_ADDRESS'],
        subject: "購読処理中にエラーがおきました (#{e.name})",
        text: e.backtrace)
    end
  end

  post '/subscribe_confirm' do
    begin
      response = mg_client.get("lists/#{mailing_list_address}/members/#{params['email']}").to_h
      if response.to_h.dig("member", "subscribed")
        redirect to('/already_subscribed')
      else
        send_confirmation_mail(address: params['email'], type: :subscribe)
        haml :subscribe_confirm
      end
    rescue Mailgun::CommunicationError => e
      send_confirmation_mail(address: params['email'], type: :subscribe)
      haml :subscribe_confirm
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
        send_confirmation_mail(address: params['email'], type: :unsubscribe)
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
