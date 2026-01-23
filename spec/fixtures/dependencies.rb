# frozen_string_literal: true

require 'low_dependency'

require_relative '../../lib/low_type'

LowDependency.provide(:dependency) do
  'mock dependency'
end

LowDependency.provide(:symbol) do
  'mock symbol dependency'
end

LowDependency.provide('string') do
  'mock string dependency'
end

class Dependencies
  include LowType

  def dependency(dependency: Dependency)
    dependency
  end

  def symbol_dependency(dependency: Dependency | :symbol)
    dependency
  end

  def string_dependency(dependency: Dependency | 'string')
    dependency
  end
end
