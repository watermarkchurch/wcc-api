# frozen_string_literal: true

module WCC::API::RSpec
  module CollectionMatchers
    def collection_match(coll1, coll2, matcher = :eq)
      coll1 = coll1.to_a
      coll2 = coll2.to_a
      expect(coll1.size).to eq(coll2.size)

      coll1.zip(coll2).each do |actual, expected|
        expect(actual).to public_send(matcher, expected)
      end
    end
  end
end
