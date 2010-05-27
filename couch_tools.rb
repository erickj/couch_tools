require 'rubygems'
require 'json'

Dir.glob(File.join("lib", "**","*.rb")) do |f_name|
  require f_name
end
