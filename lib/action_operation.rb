require "active_support/concern"
require "active_support/core_ext/array"
require "smart_params"

module ActionOperation
  extend ActiveSupport::Concern

  require_relative "action_operation/version"
  require_relative "action_operation/types"
  require_relative "action_operation/error"

  State = Struct.new(:raw)
  Drift = Struct.new(:to)

  attr_reader :raw
  attr_reader :state
  attr_reader :step

  def initialize(raw:)
    @raw = raw
  end

  def call(forced: nil)
    right.from(forced || 0).reduce(state || raw) do |state, function|
      next state unless function.required || (forced && right.at(forced) == function)

      # NOTE: We store this so we can go drift back if an error tells us to
      @state = state

      # NOTE: We store this so an error step can ask for the last ran step
      @step = function.name

      raise Error::MissingTask, function unless function.receiver.steps.key?(function.as)
      raise Error::MissingSchemaForTask, function unless function.receiver.schemas.key?(function.as)

      value = instance_exec(function.receiver.schemas.fetch(function.as).new(state), &function.receiver.steps.fetch(function.as))

      case value
      when State then value.raw
      when Drift then break call(forced: right.find_index { |step| step.name == value.to })
      else state
      end
    end
  rescue *left.select(&:catch).map(&:catch).uniq => handled_exception
    left.select do |failure|
      failure.catch === handled_exception
    end.reduce(handled_exception) do |exception, function|
      raise Error::MissingError, function unless function.receiver.steps.key?(function.as)

      value = instance_exec(exception, @state, @step, &function.receiver.steps.fetch(function.as))

      if value.kind_of?(Drift)
        break call(forced: right.find_index { |step| step.name == value.to })
      else
        exception
      end
    end
  end

  def fresh(raw)
    State.new(raw)
  end

  def drift(to:)
    Drift.new(to)
  end

  private def left
    self.class.left
  end

  private def right
    self.class.right
  end

  included do
    step :reraise do |exception|
      raise exception
    end
  end

  class_methods do
    def state(name, &structure)
      schemas[name] = Class.new do
        include(SmartParams)

        schema type: SmartParams::Strict::Hash, &structure
      end
    end

    def task(name, receiver: self, as: name, required: true)
      right.<<(OpenStruct.new({name: name, as: as, receiver: receiver || self, required: required}))
    end

    def error(name, receiver: self, catch: StandardError, as: name)
      left.<<(OpenStruct.new({name: name, as: as, receiver: receiver || self, catch: catch || StandardError}))
    end

    def step(name, &process)
      steps[name] = process
    end

    def call(raw = {})
      new(raw: raw).call
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

    def steps
      @steps ||= Hash.new
    end
  end
end
