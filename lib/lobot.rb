if ENV['RUBY_VERSION'] =~ /ruby-1.9/
  YAML::ENGINE.yamler = 'syck'
end

require File.expand_path('lobot/version', File.dirname(__FILE__))

module Lobot
end
