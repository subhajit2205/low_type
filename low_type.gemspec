# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'low_type'
  spec.version = Low::TYPE_VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = 'Elegant types in Ruby'
  spec.description = 'An elegant and simple way to define types in Ruby, only when you need them.'
  spec.homepage = 'https://github.com/low-rb/low_type'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/low-rb/low_type/src/branch/main'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('lib/**/*')
  end

  spec.require_paths = ['lib']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.add_dependency 'expressions', '~> 0.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
