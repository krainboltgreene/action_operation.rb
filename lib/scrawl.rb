require "forwardable"

# This is the main namespace for scrawl
class Scrawl
  extend Forwardable

  KEY_VALUE_DELIMITER = "="
  PAIR_DELIMITER = " "
  NAMESPACE_DELIMITER = "."

  attr_reader :tree
  def_delegator :tree, :to_hash
  def_delegator :tree, :to_h

  def initialize(*trees)
    @tree = trees.inject({}) { |global, tree| global.merge(tree) }
  end

  def merge(hash)
    @tree.merge!(hash.to_hash)
  end

  def inspect(namespace = nil)
    @tree.map do |key, value|
      unless value.respond_to?(:to_hash)
        "#{label(namespace, key)}#{KEY_VALUE_DELIMITER}#{element(value)}"
      else
        Scrawl.new(value).inspect(key)
      end
    end.join(PAIR_DELIMITER)
  end

  private

  def label(namespace, key)
    [namespace, key].compact.join(NAMESPACE_DELIMITER)
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
