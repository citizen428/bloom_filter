require "bit_array"
require "crc32"
require "./bloom_filter/*"

class BloomFilter
  # Filter capacity. If `count > capacity`, error probabilty might be exceeded.
  getter capacity : Int32
  # Number of unique items in filter. Includes false positives, so may undercount.
  getter count : Int32
  # Probability of getting a false positive when checking `include?`.
  getter error_probability : Float64
  # Number of hash functions required for target false positive probability
  getter hashes : Int32
  property bit_array : BitArray
  private getter seed : Int64

  def initialize(@capacity, @error_probability = 0.001)
    # See: https://hur.st/bloomfilter
    size = -(capacity * Math.log(error_probability)) / (Math.log(2) ** 2)
    @bit_array = BitArray.new(size.round.to_i32)
    @hashes = (Math.log(2) * @bit_array.size / capacity).round.to_i
    @count = 0
    @seed = Time.now.epoch
  end

  # Returns `true` if item was new, `false` otherwise
  def add(string) : Bool
    new_item = true
    indexes_for(string).each do |i|
      new_item &&= !bit_array[i]
      @bit_array[i] = true
    end
    @count += 1 if new_item
    new_item
  end

  # `false`: Item has already been added (no false negatives)
  # `true`: Likely that string has been added. `#error_probability` specified false positive rate.
  def include?(string) : Bool
    indexes_for(string).all? { |i| bit_array[i] }
  end

  # Returns the array of hash indices to set to `true`.
  private def indexes_for(string)
    hashes.times.map { |i| CRC32.checksum("#{string}:#{i + seed}") % @capacity }
  end

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
