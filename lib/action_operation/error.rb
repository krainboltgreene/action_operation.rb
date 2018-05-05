module ActionOperation
  class Error < StandardError
    require_relative "error/missing_error"
    require_relative "error/missing_schema"
    require_relative "error/missing_task"
  end
end
