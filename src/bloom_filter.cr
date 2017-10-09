require "bit_array"
require "crc32"
require "./bloom_filter/*"

class BloomFilter
  # Filter capacity. If `count > capacity`, error probabilty might be exceeded.
  getter capacity : Int32
  # Number of unique items in filter. Includes false positives, so may undercount.
  getter count : Int32
  private setter count : Int32
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
    count = 0
    indexes_for(string).each do |i|
      count += 1 unless bit_array[i]
      bit_array[i] = true
    end
    new_item = count > 0
    self.count += 1 if new_item
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
end
