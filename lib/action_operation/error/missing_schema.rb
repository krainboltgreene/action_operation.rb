module ActionOperation
  class Error
    class MissingSchema < Error
      def initialize(step:)
        @step = step
      end

      def message
        "expected to see #{@step.name} have a schema but the receiver (#{@step.receiver.name}) didn't support it"
      end
    end
  end
end
