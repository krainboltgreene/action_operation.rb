module ActiveRecord
  class Base
    def self.write(columns:, query: self, target: self.table_name, size: Write::DEFAULT_SIZE, serializer: Write::DEFAULT_SERIALIZER, &iteration)
      ActiveRecord::Write.new(columns: columns, query: query, target: target, size: size, serializer: serializer, &iteration).pool
    end
  end

  class Write
    require_relative "write/version"

    DEFAULT_SIZE = 24
    DEFAULT_SERIALIZER = ::JSON
    EMPTY_HASH = {}

    # `query` is either an ActiveRecord query object or arel
    # `columns` is a list of columns you want to have during the transaction
    # `target` is the table you want to talk to
    # `size` is the maximum number of running iterations in the pool, default: 24
    # `serializer` is the #dump duck for Array & Hash values, default: JSON
    # `transaction` is the process you want to run against your database
    def initialize(query:, columns:, target:, size:, serializer:, &transaction)
      @query = query
      @columns = columns
      @target = target
      @size = size
      @serializer = serializer
      @transaction = transaction
      @table = Arel::Table.new(@target)
      @queue = case
      when activerecord?
        @query.pluck(*@columns)
      when arel?
        ActiveRecord::Base.connection.execute(@query.to_sql).map(&:values)
      when tuple?
        @query.map { |result| result.slice(@columns) }
      when twodimensional?
        @query
      else
        raise ArgumentError, 'query wasn\'t recognizable, please use some that looks like a: ActiveRecord::Base, Arel::SelectManager, Array<*Hash>, Array<*Array>'
      end
      puts "Migrating #{@queue.count} #{@target} records"
    end

    def pool(qutex = Mutex.new)
      # Spin up a number of threads based on the `maximum` given
      1.upto(@size).map do
        Thread.new do
          loop do
            # Try to get a new queue item
            item = qutex.synchronize { @queue.shift }

            if item.nil?
              # There is no more work
              break
            else
              # Wait for a free connection
              ActiveRecord::Base.connection_pool.with_connection do
                ActiveRecord::Base.transaction do
                  # Execute each statement coming back
                  Array[instance_exec(*item, &@transaction)].each do |instruction|
                    ActiveRecord::Base.connection.execute(instruction.to_sql)
                  end
                end
              end
            end
          end
        end
      end.map(&:join)
    end

    private def activerecord?
      @query.kind_of?(ActiveRecord::Base) || @query.kind_of?(ActiveRecord::Relation)
    end

    private def arel?
      @query.kind_of?(Arel::SelectManager)
    end

    private def tuple?
      @query.kind_of?(Array) && @query.first.kind_of?(Hash)
    end

    private def twodimensional?
      @query.kind_of?(Array) && @query.first.kind_of?(Array)
    end

    private def update(id, data)
      Arel::UpdateManager.new(ActiveRecord::Base).table(@table).where(@table[:id].eq(id)).set(serialize(data))
    end

    private def insert(data)
      Arel::InsertManager.new(ActiveRecord::Base).tap { |m| m.insert(serialize(data)) }
    end

    private def serialize(data)
      data.inject(EMPTY_HASH) do |state, (key, value)|
        if value.is_a?(Array) || value.is_a?(Hash)
          state.merge(@table[key] => JSON.dump(value))
        else
          state.merge(@table[key] => value)
        end
      end
    end
  end
end
