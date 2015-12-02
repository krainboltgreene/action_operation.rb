module ActiveRecord
  class Base
    def self.write(columns:, query: self, target: self.table_name, size: Write::DEFAULT_SIZE, serializer: Write::DEFAULT_SERIALIZER, &iteration)
      ActiveRecord::Write.new(columns: columns, query: query, target: target, size: size, serializer: serializer, &iteration).pool
    end
  end
end
