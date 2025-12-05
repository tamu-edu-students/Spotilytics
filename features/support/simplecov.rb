# Start SimpleCov before anything else is loaded
require 'simplecov'

SimpleCov.command_name 'Cucumber'
SimpleCov.coverage_dir 'coverage/cucumber'

SimpleCov.start 'rails' do
  enable_coverage :branch
  add_filter %w[/spec/ /config/ /vendor/ /db/ /test/]
  add_group 'Controllers', 'app/controllers'
  add_group 'Models',       'app/models'
  add_group 'Helpers',      'app/helpers'
end
