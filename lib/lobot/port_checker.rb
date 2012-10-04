require 'timeout'
require 'socket'

module Lobot
  module PortChecker
    def self.is_listening?(host, port, timeout = 180)
      socket = nil
      Timeout.timeout(timeout) do
        until socket
          begin
            Timeout.timeout(5) do
              socket = TCPSocket.open(host, port)
            end
          rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, Timeout::Error, Errno::EHOSTUNREACH
          end
        end
      end

      true
    rescue Timeout::Error
      false
    end
  end
end