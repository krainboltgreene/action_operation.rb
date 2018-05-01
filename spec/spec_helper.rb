require "pry"
require "rspec"
require "action_operation"

require_relative "support/external"
require_relative "support/application_operation"
require_relative "support/add_to_cart_operation"
require_relative "support/azure_upload_operation"
require_relative "support/s3_upload_operation"
require_relative "support/spaces_upload_operation"
require_relative "support/document_upload_operation"

RSpec.configure do |let|
  # Exit the spec after the first failure
  let.fail_fast = true

  # Only run a specific file, using the ENV variable
  # Example: FILE=spec/blankgem/version_spec.rb bundle exec rake spec
  let.pattern = ENV["FILE"]

  # Show the slowest examples in the suite
  let.profile_examples = true

  # Colorize the output
  let.color = true

  # Output as a document string
  let.default_formatter = "doc"
end
