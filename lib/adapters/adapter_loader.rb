# frozen_string_literal: true

require_relative 'sinatra_adapter'

module Low
  module Adapter
    class Loader
      class << self
        def load(klass:, class_proxy:)
          adaptor = nil

          ancestors = klass.ancestors.map(&:to_s)
          adaptor = Sinatra.new(klass:, class_proxy:) if ancestors.include?('Sinatra::Base')

          return if adaptor.nil?

          adaptor
        end
      end
    end
  end
end
