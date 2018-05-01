module ActionOperation
  class Error
    class MissingSchemaForTask < Error
      def initialize(function)
        @function = function
      end

      def message
        "expected to see #{function.name} have a schema but the receiver (#{function.receiver.name}) didn't support it"
      end
    end
  end
end
