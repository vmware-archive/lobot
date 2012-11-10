require "httpclient"

module Lobot
  class Keychain
    attr_reader :config, :path

    def initialize(keychain_path)
      @path = keychain_path
    end

    def has_key?(key_name)
      system("sudo security find-certificate -c \"#{key_name}\" #{path} 2>&1 > /dev/null")
    end

    def fetch_remote_certificate(host)
      http_client.get(host).peer_cert.to_s
    end

    def add_certificate(certificate)
      certificate_file = Tempfile.new("lobot.crt")
      certificate_file.write(certificate)
      certificate_file.close

      system("sudo security add-trusted-cert -d -r trustAsRoot -k /Library/Keychains/System.keychain #{certificate_file.path}")
    end



    private
    def http_client
      @http_client ||=
        HTTPClient.new.tap do |hc|
          hc.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
    end
  end
end
