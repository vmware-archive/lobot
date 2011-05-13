if ENV['RUBY_VERSION'] =~ /ruby-1.9/
  YAML::ENGINE.yamler = 'syck'
end

module Lobot
end
