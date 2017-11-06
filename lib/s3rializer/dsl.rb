module S3rializer
  module DSL
    def serializes(klass)
      self.resource_klass = klass
    end

    def preserves_nils(keep_nils = true)
      self.keep_nils = keep_nils
    end

    def dumps_with(dumper)
      self.dumper = dumper
    end

    def exposed_attributes(*attributes)
      assert_symbols!(*attributes)

      attributes.each do |attribute|
        attribute_callbacks[attribute] = -> { @resource.__send__(attribute) }
      end
    end

    def renamed_attribute(public_attribute, resource_attribute)
      assert_symbols!(public_attribute, resource_attribute)
      attribute_callbacks[public_attribute] = -> { @resource.__send__(resource_attribute) }
    end

    def transformed_attributes(*attributes, with:)
      assert_symbols!(*attributes)

      transformation =
        if with.is_a?(Symbol)
          ->(value) { __send__(with, value) }
        elsif with.is_a?(Class) && with < Serializer
          ->(value) { with.compile(value) if value }
        else
          with
        end

      assert_callable!(transformation)

      attributes.each do |attribute|
        callback = -> { instance_exec(@resource.__send__(attribute), &transformation) }
        attribute_callbacks[attribute] = callback
      end
    end

    def computed_attribute(attribute, with:)
      assert_symbols!(attribute)

      computation =
        if with.is_a?(Symbol)
          -> { __send__(with, @resource) }
        else
          -> { with.call(@resource) }
        end

      assert_callable!(computation)

      attribute_callbacks[attribute] = computation
    end

    def assert_symbols!(*attributes)
      return unless (violator = attributes.detect { |attribute| !attribute.is_a?(Symbol) })
      raise ArgumentError, "attribute must be a symbol (got #{violator.inspect})"
    end

    def assert_callable!(callback)
      return if callback.respond_to?(:call)
      raise ArgumentError, "callback must be callable (got #{callback.inspect})"
    end

    alias exposed_attribute exposed_attributes
    alias transformed_attribute transformed_attributes
  end
end
