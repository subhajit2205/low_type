# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/dependencies'

RSpec.describe Dependencies do
  subject { described_class.new }

  describe '.included' do
    it 'redefines methods on class load' do
      expect(described_class.low_methods.keys).to include(
        :dependency,
        :symbol_dependency,
        :string_dependency
      )
    end
  end

  describe '#dependency' do
    it 'uses the keyword argument as the provider key and returns a value' do
      expect(subject.dependency).to eq('mock dependency')
    end
  end

  describe '#symbol_dependency' do
    it 'returns a value' do
      expect(subject.symbol_dependency).to eq('mock symbol dependency')
    end
  end

  describe '#string_dependency' do
    it 'returns a value' do
      expect(subject.string_dependency).to eq('mock string dependency')
    end
  end
end
