require 'pp'
require 'pinbo'
Pinbo.start :script_name => '/go!'

Object.send :include, Pinbo::Timer

timer :te => :tete do
  sleep 1
end

timer :ma => :meme, :re => :riri do
  sleep 1
end

Pinbo.stop