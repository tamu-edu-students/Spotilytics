# spec/simplecov_helper.rb
require 'simplecov'
SimpleCov.start 'rails' do
  enable_coverage :branch
  add_filter %w[/config/ /vendor/ /spec/ /features/]
end

SimpleCov.minimum_coverage 90
SimpleCov.coverage_dir 'coverage'
SimpleCov.command_name 'RSpec' # default name for rspec runs
puts "SimpleCov started for RSpec/Cucumber combined coverage"