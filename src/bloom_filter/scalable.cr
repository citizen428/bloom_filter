class BloomFilter
  # Automatically expanding bloom filter.
  # See http://gsd.di.uminho.pt/members/cbm/ps/dbloom.pdf
  class Scalable
    SCALE = 2
    RATIO = Math.log(2) ** 2

    # Probability of getting a false positive when checking `include?`.
    getter error_probability : Float64
    private property filters : Array(BloomFilter)

    def initialize(initial_capacity = 256, @error_probability = 0.001)
      @filters = [BloomFilter.new(initial_capacity, error_probability * RATIO)]
    end

    def capacity
      filters.last.capacity
    end

    def count
      filters.sum(&.count)
    end

    def add(string)
      filter = filters.last
      added = filter.add(string)
      if added && (filter.count > filter.capacity)
        new_capacity = filter.capacity * SCALE
        new_error_probability = error_probability * (RATIO ** filters.size)
        filters << BloomFilter.new(new_capacity, new_error_probability)
      end
      added
    end

    #  Returns `false` if none of the filters contains `string`.
    def include?(string)
      filters.any? { |filter| filter.include?(string) }
    end
  end
end
