module ActionOperation
  class Error
    class MissingTask < Error
      def initialize(function)
        @function = function
      end
    end
  end
end
