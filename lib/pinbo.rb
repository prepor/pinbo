require 'rubygems'
require 'socket'
require 'timeout'
require 'ruby_protobuf'
require "socket"
require 'proto/pinbo.pb'

module Pinbo

  require 'pinbo/timer'
  require 'pinbo/request'
  require 'pinbo/middleware'
  
  Config = {
    :host => Socket.gethostname,
    :pinba_host => '74.86.33.154', #:pinba_host => 'localhost',
    :pinba_port => 30002
  }
  
  class << self
  
    def counter
      Thread.current[:counter] ||= 1
    end
  
    def counter=(val)
      Thread.current[:counter] = val
    end
  
    def data
      Thread.current[:data]
    end
  
    def data=(val)
      Thread.current[:data] = val
    end
  
    def timers
      Thread.current[:timers]
    end
  
    def timers=(val)
      Thread.current[:timers] = val
    end
  
    def increase_counter
      self.counter += 1
    end
  
    def start(options = {})
      Thread.current[:request_start] = Time.now
      Thread.current[:timer_counter] = 0
      self.data = { 
                    :server_name => Socket.gethostname,
                    :script_name => '/test.rb',
                    :request_count => counter,
                    :document_size => 0,
                    :memory_peak => 0,
                    :request_time => 0,
                    :ru_utime => 0,
                    :ru_stime => 0,
                    :status => 200 }.merge(options)
      self.timers = []
    end
  
    def timer_counter
      Thread.current[:timer_counter] += 1
      Thread.current[:timer_counter] - 1
    end
  
    def stop(options = {})
      data.merge!( :request_time => Time.now - Thread.current[:request_start] ).merge!(options)
      Request.new( :data => data, :timers => timers).perform
      increase_counter
    end
  
    def timer(tags = {}, &block)
      t = get_timer(tags)
      t[:start] = Time.now
      block.call
      time = Time.now
      t[:counter] += 1
      t[:stop] = time
      t[:period] += t[:stop] - t[:start]
    end
    
    def normalize_tags(raw_tags)
      raw_tags.map { |k, v| { :name_id => timer_counter, :value_id => timer_counter, :name => k.to_s, :value => v.to_s } }
    end
    
    def get_timer(tags)
      unless (t = self.timers.detect { |v| v[:tags] == tags } ) 
        t = { :tags => tags, :normalized_tags => normalize_tags(tags), :counter => 0, :period => 0 }
        self.timers << t
      end
      t
    end
  end
  
end