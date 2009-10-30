require 'pp'
require 'pinbo'
Pinbo.start :script_name => '/go!'

Object.send :include, Pinbo::Timer

timer :a => :foo, :b => :bar do
  sleep 1
end

Pinbo.stop