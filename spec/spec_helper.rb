# Load the Sinatra app
require File.dirname(__FILE__) + '/../app'

require 'rspec'
require 'sinatra'
require 'capybara/rspec'
require 'valid_attribute'
require 'rack/test'
require 'factory_girl'
require 'factories'

set :environment, :test

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  def app
    Barcode
  end
end
