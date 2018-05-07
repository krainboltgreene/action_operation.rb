require "active_support/concern"
require "active_support/core_ext/array"
require "smart_params"

module ActionOperation
  extend ActiveSupport::Concern

  require_relative "action_operation/version"
  require_relative "action_operation/error"
  require_relative "action_operation/types"

  State = Struct.new(:raw)
  Drift = Struct.new(:to)
  Task = Struct.new(:name, :receiver, :required)
  Catch = Struct.new(:name, :receiver, :exception)

  def initialize(raw:)
    raise ArgumentError, "needs to be a Hash" unless raw.kind_of?(Hash)

    @raw = raw
  end

  def call(start: nil, raw: @raw)
    around_steps(raw: raw) do
      begin
        around_tasks(raw: raw) do
          tasks(start, raw)
        end
      rescue *left.select(&:exception).map(&:exception).uniq => handled_exception
        around_catches(exception: handled_exception, raw: raw) do
          catches(handled_exception, raw)
        end
      end
    end
  end

  private def tasks(start, raw)
    right.from(start || 0).reduce(raw) do |state, step|
      next state unless step.required || (start && right.at(start) == step)

      raise Error::MissingTask, step: step unless respond_to?(step.name)
      raise Error::MissingSchema, step: step unless self.class.schemas.key?(step.name)

      # NOTE: We only care about this so we can reference it in the rescue
      @latest_step = step

      # puts "#{step.class}::#{step.receiver}##{step.name}"

      begin
        value = around_task(state: self.class.schemas.fetch(step.name).new(state), raw: raw, step: step) do
          public_send(step.name, state: self.class.schemas.fetch(step.name).new(state))
        end
        # puts "#{step.class}::#{step.receiver}##{step.name} #{value}"
      rescue SmartParams::Error::InvalidPropertyType => invalid_property_type_exception
        raise Error::StepSchemaMismatch, step: step, schema: self.class.schemas.fetch(step.name), raw: raw, cause: invalid_property_type_exception
      end

      case value
        when State then value.raw
        when Drift then break call(start: right.find_index { |step| step.name == value.to }, raw: state)
        else state
      end
    end
  end

  private def catches(exception, raw)
    left.select do |failure|
      failure.exception === exception
    end.reduce(exception) do |exception, step|
      raise Error::MissingError, step: step unless respond_to?(step.name)

      # puts "#{step.class}::#{step.receiver}##{step.name}"

      begin
        value = around_catch(exception: exception, raw: raw, step: step) do
          public_send(step.name, exception: exception, state: raw, step: @latest_step)
        end
        # puts "#{step.class}::#{step.receiver}##{step.name} #{value}"
      rescue SmartParams::Error::InvalidPropertyType => invalid_property_type_exception
        raise Error::StepSchemaMismatch, step: @latest_step, schema: self.class.schemas.fetch(@latest_step.name), raw: raw, cause: invalid_property_type_exception
      end

      if value.kind_of?(Drift)
        break call(start: right.find_index { |step| step.name == value.to }, raw: raw)
      else
        exception
      end
    end
  end

  def fresh(state:)
    raise ArgumentError, "needs to be a Hash" unless state.kind_of?(Hash)

    State.new(state)
  end

  def drift(to:)
    raise ArgumentError, "needs to be a Symbol or String" unless to.kind_of?(Symbol) || to.kind_of?(String)

    Drift.new(to)
  end

  def around_steps(&callback)
    callback.call
  end

  def around_step(&callback)
    callback.call
  end

  def around_tasks(&callback)
    callback.call
  end

  def around_task(&callback)
    callback.call
  end

  def around_catches(&callback)
    callback.call
  end

  def around_catch(&callback)
    callback.call
  end

  private def left
    self.class.left
  end

  private def right
    self.class.right
  end

  def reraise(exception:, **)
    raise exception
  end

  class_methods do
    def call(raw = {})
      new(raw: raw).call
    end

    def schema(name, &structure)
      schemas[name] = Class.new do
        include(SmartParams)

        schema type: SmartParams::Strict::Hash, &structure
      end
    end

    def task(name, required: true)
      right << Task.new(name, self, required)
    end

    def catch(name, exception: StandardError)
      left << Catch.new(name, self, exception)
    end

    def right
      @right ||= Array.new
    end

    def left
      @left ||= Array.new
    end

    def schemas
      @schemas ||= Hash.new
    end
  end
end
