module Pinbo
  class Request
    attr_accessor :options
    def initialize(options)
      self.options = options
    end
  
    def cmd
      req = Proto::Pinbo::Request.new 
      req.hostname = Config[:host]
      req.server_name = options[:data][:server_name]
      req.script_name = options[:data][:script_name]
      req.request_count = options[:data][:request_count]
      req.document_size = options[:data][:document_size]
      req.memory_peak = options[:data][:memory_peak]
      req.request_time = options[:data][:request_time]
      req.ru_utime = options[:data][:ru_utime]
      req.ru_stime = options[:data][:ru_stime]
      Pinbo.timers.each do |timer|
         req.timer_hit_count << timer[:counter]
         req.timer_value << timer[:period]
         req.timer_tag_count << timer[:tags].size
         timer[:normalized_tags].each do |tag|
           req.timer_tag_name << tag[:name_id]
           req.dictionary << tag[:name]
           req.timer_tag_value << tag[:value_id]
           req.dictionary << tag[:value]
         end
       end
      req.status = options[:data][:status]
      # require 'ruby-debug'
      # debugger
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
end