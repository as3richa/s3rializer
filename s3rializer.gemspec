require_relative 'lib/s3rializer.rb'

Gem::Specification.new do |s|
  s.name        = 's3rializer'
  s.version     = S3rializer::VERSION
  s.summary     = 'Simple serialization DSL for Ruby objects, like ActiveModelSerializers'
  s.description =
    'A simple DSL for defining serializers for Ruby objects. ' \
    'Conceptually and functionally very similar to ActiveModelSerializers.'
  s.authors     = 'Adam Richardson (as3richa)'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'https://github.com/as3richa/s3rializer'
  s.license     = 'MIT-Zero'

  # This is when class_attribute was introduced 
  s.add_runtime_dependency 'activesupport', '>= 3.0.0'

  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'rubocop', '~> 0.42.0'
end