module ActionOperation
  class Error
    class MissingTask < Error
      def initialize(function)
        @function = function
      end

      def message
        "expected to see #{function.name} but the receiver (#{function.receiver.name}) didn't support it"
      end
    end
  end
end
