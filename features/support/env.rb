require "rubygems"
require File.expand_path('../../lib/lobot', File.dirname(__FILE__))
LOBOT_TEMP_DIRECTORY = "/tmp/lobot-test"

def system!(str)
  system(str)
  raise "Command Failed: #{str} with exit code #{$?.exitstatus}" unless $?.success?
end

After '@aws' do
  system! "cd #{LOBOT_TEMP_DIRECTORY}/testapp && rake ci:terminate"
end
