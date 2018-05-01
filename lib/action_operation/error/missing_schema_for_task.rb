module ActionOperation
  class Error
    class MissingSchemaForTask < Error
      def initialize(function)
        @function = function
      end
    end
  end
end
