module ActionOperation
  class Error < StandardError
    require_relative "error/missing_error"
    require_relative "error/missing_schema"
    require_relative "error/missing_task"
    require_relative "error/step_schema_mismatch"
  end
end
