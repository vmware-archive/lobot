require File.expand_path('lobot/version', File.dirname(__FILE__))
require 'headless'

module Lobot
  def self.rails3?
    return Rails.version.split(".").first.to_i == 3 if defined? Rails
    begin
      Gem::Specification::find_by_name "rails", ">= 3.0"
    rescue
      Gem.available? "rails", ">= 3.0"
    end
  end
end

require File.expand_path(File.join('lobot', "railtie"), File.dirname(__FILE__)) if Lobot.rails3?
