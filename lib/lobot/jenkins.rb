module Lobot
  class Jenkins
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def jobs
      Hashie::Mash.new(api_json).jobs
    end

    def api_json
      JSON.parse(`curl -s http://#{config.master}:8080/api/json`)
    end
  end
end
