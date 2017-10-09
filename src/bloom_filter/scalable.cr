class BloomFilter
  # Automatically expanding bloom filter.
  # See http://gsd.di.uminho.pt/members/cbm/ps/dbloom.pdf
  class Scalable
    SCALE = 2
    RATIO = Math.log(2) ** 2

    # Probability of getting a false positive when checking `include?`.
    getter fp_probability : Float64
    private property filters : Array(BloomFilter)

    def initialize(initial_capacity = 256, @fp_probability = 0.001)
      @filters = [BloomFilter.new(initial_capacity, fp_probability * RATIO)]
    end

    # Filter capacity. Increases automatically to maintain `#fp_probability`.
    def capacity
      filters.last.capacity
    end

    # Number of items in the filter (n). Includes false positives, so may undercount.
    def count
      filters.sum(&.count)
    end

    # Returns `true` if item was new, `false` otherwise
    def add(string)
      filter = filters.last
      added = filter.add(string)
      if added && (filter.count > filter.capacity)
        new_capacity = filter.capacity * SCALE
        new_fp_probability = fp_probability * (RATIO ** filters.size)
        filters << BloomFilter.new(new_capacity, new_fp_probability)
      end
      added
    end

    # Bulk `add`s from an enumerable. Returns `true` if at least one new item was added.
    def add_from(strings)
      new_items = strings.map { |s| filters.last.add(s) }
      new_items.any?
    end

    # Prints some statistics about the filter, mainly for debugging purposes.
    def stats
      filters.last.stats
    end

    #  Returns `false` if none of the filters contains `string`.
    def includes?(string)
      filters.any? { |filter| filter.includes?(string) }
    end
  end
end
