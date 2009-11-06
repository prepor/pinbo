require 'rubygems'
require 'socket'
require 'timeout'
require 'ruby_protobuf'
require 'proto/pinbo.pb'

module Pinbo
  
  Config = {
    :host => 'Andrew-Rudenkos-Mac-Pro.local',
    :server_name => 'localhost',
    :key => 'asdagsdf',
    :pinba_host => '86400.ru', #:pinba_host => 'localhost',
    :pinba_port => 30003
  }
  
  def self.counter
    @@counter ||= 1
  end
  
  def self.counter=(val)
    @@counter = val
  end
  
  def self.data
    @@data
  end
  
  def self.data=(val)
    @@data = val
  end
  
  def self.timers
    @@timers
  end
  
  def self.timers=(val)
    @@timers = val
  end
  
  def self.increase_counter
    self.counter += 1
  end
  
  def self.start(options = {})
    @@request_start = Time.now
    @@timer_counter = 0
    self.data = { 
                  :script_name => '/test.php',
                  :request_count => counter,
                  :document_size => 0,
                  :memory_peak => 0,
                  :request_time => 0,
                  :ru_utime => 0,
                  :ru_stime => 0 }.merge(options)
    self.timers = []
  end
  
  def self.timer_counter
    @@timer_counter += 1
    @@timer_counter - 1
  end
  
  def self.stop(options = {})
    data.merge!( :request_time => Time.now - @@request_start ).merge!(options)
    Request.new( :data => data, :timers => timers).perform
    increase_counter
  end
  
  def self.timer(tags = {}, &block)
    t = { :tags => tags.map { |k, v| { :name_id => timer_counter, :value_id => timer_counter, :name => k.to_s, :value => v.to_s }}, :start => Time.now }
    
    self.timers << t
    block.call
    time = Time.now
    t[:stop] = time
    t[:period] = t[:stop] - t[:start]
  end
  
  class Request
    attr_accessor :options
    def initialize(options)
      self.options = options
    end
    
    def cmd
      req = Proto::Pinbo::Request.new 
      req.hostname = Config[:host]
      req.server_name = Config[:server_name]
      req.script_name = options[:data][:script_name]
      req.request_count = options[:data][:request_count]
      req.document_size = options[:data][:document_size]
      req.memory_peak = options[:data][:memory_peak]
      req.request_time = options[:data][:request_time]
      req.ru_utime = options[:data][:ru_utime]
      req.ru_stime = options[:data][:ru_stime]
      Pinbo.timers.each do |timer|
         req.timer_hit_count << 1 # это надо реализовать
         req.timer_value << timer[:period]
         req.timer_tag_count << timer[:tags].size
         timer[:tags].each do |tag|
           req.timer_tag_name << tag[:name_id]
           req.dictionary << tag[:name]
           req.timer_tag_value << tag[:value_id]
           req.dictionary << tag[:value]
         end
       end
      req.status = 200
      req.serialize_to_string
    end
    
    def perform
      sock = nil
      begin
        sock = UDPSocket.open        
        sock.send(cmd, 0, Config[:pinba_host], Config[:pinba_port])
      rescue IOError, SystemCallError
      ensure
        sock.close if sock
      end
    end
  end
  
  module Timer
    def timer(tags = {}, &block)
      Pinbo.timer(tags, &block)
    end
  end
  
  class Middleware
    def initialize(app)
      @app = app
    end
    
    def call(env)
      Pinbo.start :script_name => env.path_info
      @app.call(env)
      Pinbo.stop
    end
  end
  
end