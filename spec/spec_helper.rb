require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'support/matchers'

RSpec.configure do |c|
  c.filter_run(focus: true)
  c.run_all_when_everything_filtered = true

  # Default platform / version to mock Ohai data from
  c.platform = 'ubuntu'
  c.version = '14.04'

  # Don't clear cookbooks from the server-runner between each test for performance
  c.server_runner_clear_cookbooks = false

end
