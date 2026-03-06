# frozen_string_literal: true

require 'low_type'

RSpec.describe 'Boolean Type' do
  class BoolTest
    include LowType

    def check(status: Boolean | false)
      status
    end
  end

  subject(:instance) { BoolTest.new }

  it 'returns true when true is passed' do
    expect(instance.check(status: true)).to eq(true)
  end

  it 'returns false when false is passed' do
    expect(instance.check(status: false)).to eq(false)
  end

  it 'uses default value when argument is not passed' do
    expect(instance.check).to eq(false)
  end

  it 'raises an error as non boolean value is passed' do
    expect {
      instance.check(status: "Error")
    }.to raise_error(Low::ArgumentTypeError)
  end
end