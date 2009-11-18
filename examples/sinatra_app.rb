require 'rubygems'
require 'sinatra'
require 'pinbo'

Object.send :include, Pinbo::Timer

use Pinbo::Middleware
get '/' do
  timer :layout => :index, :action => :generate_all do
    2 + 2 * 4
  end
  "Hello World!"
end