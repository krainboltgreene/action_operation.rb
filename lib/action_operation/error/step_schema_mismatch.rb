module ActionOperation
  class Error
    class StepSchemaMismatch < Error
      def initialize(step:, schema:, raw:)
        @step = step
        @schema = schema
        @raw = raw
      end

      def message
        "#{@step.receiver}##{@step.name} #{cause.message} and received #{@raw}"
      end
    end
  end
end
