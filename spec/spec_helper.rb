# encoding: utf-8

require 'dais'
require 'pry'
Dir[Pathname(__FILE__).dirname.join('support/**/*.rb').to_s].each do |file|
  require file
end
