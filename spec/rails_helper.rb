# frozen_string_literal: true

require "spec_helper"

# Assigned rather than defaulted with ||=: the development container already
# exports RAILS_ENV=development, and a spec run must never touch that database.
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"

abort("The Rails environment is not test mode!") unless Rails.env.test?

require "rspec/rails"

Rails.root.glob("spec/support/**/*.rb").sort.each { |file| require file }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => error
  abort error.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include DocumentFactory
  config.include ActiveSupport::Testing::TimeHelpers
end
