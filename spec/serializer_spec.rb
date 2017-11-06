require_relative '../lib/s3rializer.rb'

describe S3rializer::Serializer do
  def unregister_klasses(*klasses)
    klasses.each { |klass| Object.send(:remove_const, klass.name.to_sym) }
  end

  class Hash
    def sort_keys
      map.sort.to_h
    end
  end

  describe 'basic functionality' do
    after(:all) { unregister_klasses(DataObject, DataObjectSerializer) }

    class DataObject
      attr_accessor :id, :x, :y, :z

      def initialize(id, x, y, z)
        @id = id
        @x = x
        @y = y
        @z = z
      end
    end

    class DataObjectSerializer < S3rializer::Serializer
      serializes DataObject

      exposed_attributes :id, :x, :y
      renamed_attribute :original_z, :z

      transformed_attribute :z, with: ->(z) { z * 100 }

      computed_attribute :sum, with: ->(datum) { datum.x + datum.y + datum.z }
      computed_attribute :avg, with: :average
      computed_attribute :is_pythagorean, with: ->(datum) { datum.x**2 + datum.y**2 == datum.z**2 }

      def average(datum)
        (datum.x + datum.y + datum.z) / 3.0
      end
    end

    it 'implements basic DSL semantics correctly' do
      {
        [1, 3, 4, 5] =>
          {
            id: 1,
            x: 3,
            y: 4,
            original_z: 5,
            z: 500,
            sum: 12,
            avg: 4.0,
            is_pythagorean: true
          }.sort_keys,

        [2, 13, 37, 1000] =>
          {
            id: 2,
            x: 13,
            y: 37,
            original_z: 1000,
            z: 10**5,
            sum: 1050,
            avg: 1050 / 3.0,
            is_pythagorean: false
          }.sort_keys,

        [3, 100, 100, 100] =>
          {
            id: 3,
            x: 100,
            y: 100,
            original_z: 100,
            z: 10_000,
            sum: 300,
            avg: 100.0,
            is_pythagorean: false
          }.sort_keys
      }.each do |params, expectation|
        datum = DataObject.new(*params)

        expect(DataObjectSerializer.compile(datum)).to eq(expectation)
        expect(DataObjectSerializer.new(datum).compile).to eq(expectation)
        expect(DataObjectSerializer.serialize(datum)).to eq(JSON.dump(expectation))
        expect(DataObjectSerializer.new(datum).serialize).to eq(JSON.dump(expectation))
      end
    end
  end
end
