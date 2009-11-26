module Pinbo
  class Middleware
    def initialize(app)
      @app = app
    end
  
    def call(env)
      Pinbo.start :script_name => env['PATH_INFO']
      res = @app.call(env)
      Pinbo.stop :status => res[0], :server_name => env['SERVER_NAME'], :document_size => res[1]['Content-Length'].to_i
      res
    end
  end
end