require 'socket'
require 'timeout'


module Pinbo
  
  Config = {
    :host => 'example.com',
    :server_name => 'app',
    :key => 'asdagsdf'    
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
    self.data = { 
                  :script_name => nil,
                  :request_count => counter,
                  :document_size => nil,
                  :memory_peak => nil,
                  :request_time => nil,
                  :ru_utime => nil,
                  :ru_stime => nil }.merge(options)
    self.timers = []
  end
  
  def self.stop(options = {})
    data.merge!( :request_time => Time.now - @@request_start ).merge!(options)
    Request.new( :data => data, :timers => timers).perform
    increase_counter
  end
  
  def self.timer(tags = {}, &block)
    t = { :tags => tags, :start => Time.now }
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
      req = Proto::Pinbo.new 
      req.hostname = Config[:hostname]
      req.server_name = Config[:server_name]
      req.script_name = options[:data][:script_name]
      req.request_count = options[:data][:request_count]
      req.document_size = options[:data][:document_size]
      req.memory_peak = options[:data][:memory_peak]
      req.request_time = options[:data][:request_time]
      req.ru_utime = options[:data][:ru_utime]
      req.ru_stime = options[:data][:ru_stime]
    end
    
    def perform
      
      pp options
      # sock = nil
      # begin
      #   sock = UDPSocket.open
      #   sock.send(cmd, 0, Pinbo.config[:server_host], Pinbo.config[:server_port])
      # rescue IOError, SystemCallError
      # ensure
      #   sock.close if sock
      # end
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