VALID_SESSION_TERM = 60 * 60 * 3 # sec

require 'bundler'
Bundler.require

require 'rack/protection'
require 'mailgun'
require './app'

use Rack::Session::Pool, expire_after: VALID_SESSION_TERM
use Rack::Protection
run App
