
    class Headers
      def initialize(app)
        @app = app
      end
  
      def call(env)
        status, headers, body = @app.call(env)
  
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = '*'
        headers['Access-Control-Allow-Headers'] = '*'
        headers['Access-Control-Request-Method'] = '*'
  
        [status, headers, body]
      end
    end
  
  