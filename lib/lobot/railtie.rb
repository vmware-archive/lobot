require "rails/railtie"
module Lobot
  class Railtie < Rails::Railtie

    config.before_configuration do
      old_lobot_rakefile = ::Rails.root.join('lib', 'tasks', 'ci.rake')
      if old_lobot_rakefile.exist? && !ENV["USE_CI_RAKE"]
        puts %Q{
            You no longer need to have ci.rake in your project, as it is now automatically loaded
            from the Lobot gem. To silence this warning, set "USE_CI_RAKE=true" in your environment
            or remove ci.rake.
          }
      end
    end

    rake_tasks do
      load "lobot/tasks/ci.rake"
    end
  end
end