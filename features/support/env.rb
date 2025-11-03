require 'simplecov'
SimpleCov.command_name 'Cucumber'
SimpleCov.enable_coverage :branch
SimpleCov.start 'rails' do
  add_filter '/spec/'    
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_group 'Models',      'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers',     'app/helpers'
  add_group 'Views',       'app/views'
  coverage_dir 'coverage'  
end
puts 'SimpleCov started for Cucumber'

require 'cucumber/rails'
require 'capybara/rails'
require 'capybara/cucumber'
require 'database_cleaner/active_record'
require 'rspec/mocks'
require 'rack_session_access/capybara'

World(RSpec::Mocks::ExampleMethods)

Before { RSpec::Mocks.setup }
After  { RSpec::Mocks.verify; RSpec::Mocks.teardown }

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "Add database_cleaner to Gemfile (:test) to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation
Capybara.default_driver = :rack_test