require 'rubygems'
require 'sinatra'
require 'pinbo'

use Pinbo::Middleware
get '/' do
  "Hello World!"
end