module ActionOperation
  class Error
    class MissingError < Error
      def initialize(step:)
        @step = step
      end

      def message
        "expected to see #{@step.name} but the receiver (#{@step.receiver.name}) didn't support it"
      end
    end
  end
end
