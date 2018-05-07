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
    right.from(start || 0).reduce(raw) do |state, step|
      next state unless step.required || (start && right.at(start) == step)

      raise Error::MissingTask, step unless respond_to?(step.name)
      raise Error::MissingSchema, step unless self.class.schemas.key?(step.name)

      # NOTE: We only care about this so we can refernece it in the rescue
      @latest_step = step

      value = public_send(step.name, state: self.class.schemas.fetch(step.name).new(state))

      case value
      when State then value.raw
      when Drift then break call(start: right.find_index { |step| step.name == value.to }, raw: raw)
      else state
      end
    end
  rescue *left.select(&:exception).map(&:exception).uniq => handled_exception
    left.select do |failure|
      failure.exception === handled_exception
    end.reduce(handled_exception) do |exception, step|
      raise Error::MissingError, step unless respond_to?(step.name)

      value = public_send(step.name, exception: exception, state: self.class.schemas.fetch(@latest_step.name).new(raw), step: @latest_step)

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
