require "haddock"

module Lobot
  class Password
    class << self
      def generate
        Haddock::Password.generate
      rescue Haddock::Password::NoWordsError
        return ""
      end
    end
  end
end