require 'json'
require 'active_support'
require 'active_support/core_ext/class/attribute.rb'

require_relative 'dsl.rb'

module S3rializer
  class Serializer
    SCALAR_TYPES = [String, Integer, Float, TrueClass, FalseClass, Symbol].freeze

    def initialize(resource)
      if resource_klass.nil?
        raise 'resource_klass is unset; call `serializes` at the class level'
      end

      unless resource.is_a?(self.class.resource_klass)
        raise ArgumentError, "#{resource.inspect} isn't a #{resource_klass}"
      end

      @resource = resource
    end

    def self.serialize(resource)
      dumper.dump(compile(resource))
    end

    def self.compile(resource)
      return resource.map { |r| new(r).compile } if arrayish?(resource)
      new(resource).compile
    end

    def serialize
      dumper.dump(compile)
    end

    def compile
      result_pairs =
        attribute_callbacks.map { |attribute, callback| [attribute, instance_exec(&callback)] }
                           .map { |attribute, raw_value| [attribute, compile_value(raw_value)] }
                           .sort

      result_pairs.reject! { |_, value| value.nil? } unless keep_nils
      assert_serializable!(result_pairs.to_h)
    end

    private

    class_attribute :resource_klass
    class_attribute :dumper
    class_attribute :attribute_callbacks
    class_attribute :keep_nils

    def assert_serializable!(object)
      case object
      when NilClass
        nil
      when Hash
        object.each_value { |obj| assert_serializable!(obj) }
      when Enumerable
        object.each { |obj| assert_serializable!(obj) }
      when *SCALAR_TYPES
        nil
      else
        raise ArgumentError, "#{object.inspect} isn't serializable"
      end
      object
    end

    def compile_value(value)
      case value
      when NilClass
        nil
      when Hash
        value.map { |key, val| [key, compile_value(val)] }.to_h
      when Enumerable
        value.map { |val| compile_value(val) }
      when *SCALAR_TYPES
        value
      else
        raise ArgumentError, "don't know how to compile #{value.inspect}"
      end
    end

    class << self
      include DSL

      def inherited(subclass)
        subclass.resource_klass = resource_klass
        subclass.dumper = dumper || JSON
        subclass.attribute_callbacks = attribute_callbacks.dup || {}
        subclass.keep_nils = keep_nils || false
      end

      def arrayish?(object)
        object.is_a?(Enumerable) && !object.is_a?(Hash) && !object.is_a?(Struct)
      end
    end
  end
end
