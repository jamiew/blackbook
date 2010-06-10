begin
  require 'config_reader'

  class SiteConfig < ConfigReader
    self.config_file = RAILS_ROOT+"/config/settings.yml"
  end
rescue LoadError
  STDERR.puts "config_reader gem not installed"
end
