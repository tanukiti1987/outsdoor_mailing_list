VALID_SESSION_TERM = 60 * 60 * 3 # sec

require 'bundler'
Bundler.require(:default, ENV['RACK_ENV'])

require 'pry' unless ENV['RACK_ENV'] == 'production'

require 'rack/protection'

require 'mailgun'
require './app'

if ENV['RACK_ENV'] == 'production'
  require 'rack/ssl'
  use Rack::SSL
end

use Rack::Session::Pool, expire_after: VALID_SESSION_TERM
use Rack::Protection
run App
