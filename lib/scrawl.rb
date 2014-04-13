require "forwardable"
# This is the main namespace for scrawl
class Scrawl
  extend Forwardable

  KEY_VALUE_DELIMITER = "=".freeze
  PAIR_DELIMITER = " ".freeze
  NAMESPACE_DELIMITER = ".".freeze

  attr_reader :tree
  def_delegator :tree, :to_hash
  def_delegator :tree, :to_h

  def initialize(*trees)
    @tree = trees.inject({}) { |global, tree| global.merge(tree) }
  end

  def merge(hash)
    @tree.merge(hash.to_h)
  end

  def inspect(namespace = nil)
    @tree.map do |key, value|
      if value.is_a?(Hash)
        Scrawl.new(value).inspect(key)
      else
        "#{label(namespace, key)}#{KEY_VALUE_DELIMITER}#{element(value)}"
      end
    end.join(PAIR_DELIMITER)
  end

  private

  def label(namespace, key)
    [namespace, key].compact.map(&:to_s).join(NAMESPACE_DELIMITER)
  end

  def element(value)
    case value
    when Proc then value.call
    when Numeric then value
    when Symbol then value.to_s
    else value
    end.inspect
  end
end

require_relative "scrawl/version"
