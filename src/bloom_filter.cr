require "bit_array"
require "crc32"
require "./bloom_filter/*"

class BloomFilter
  # Filter capacity. If `count > capacity`, false positive probabilty might be exceeded.
  getter capacity : Int32
  # Required number of bits for the underlying `BitArray` (m). Automatically calculated.
  getter bits : Int32
  # Number of items in the filter (n). Includes false positives, so may undercount.
  getter count : Int32
  # Number of hash functions required for target false positive probability (k).
  # Automatically calculated.
  getter hashes : Int32
  # Probability of getting a false positive when checking `includes?` (p).
  getter fp_probability : Float64

  private setter count : Int32
  private getter seed : Int64
  private getter bit_array : BitArray

  def initialize(@capacity, @fp_probability = 0.001)
    @bits = calculate_bits
    @bit_array = BitArray.new(bits)
    @hashes = (Math.log(2) * bit_array.size / capacity).round.to_i
    @count = 0
    @seed = Time.now.epoch
  end

  # Returns `true` if item was new, `false` otherwise
  def add(string) : Bool
    hash_count = 0
    indexes_for(string).each do |i|
      hash_count += 1 unless bit_array[i]
      bit_array[i] = true
    end
    new_item = hash_count > 0
    @count += 1 if new_item
    new_item
  end

  # Bulk `add`s from an enumerable. Returns `true` if at least one new item was added.
  def add_from(strings)
    new_items = strings.map { |s| add(s) }
    new_items.any?
  end

  # `false`: Item has already been added (no false negatives)
  # `true`: Likely that string has been added. See `#fp_probability`.
  def includes?(string) : Bool
    indexes_for(string).all? { |i| bit_array[i] }
  end

  # Prints some statistics about the filter, mainly for debugging purposes.
  def stats
    fp = ((1.0 - Math.exp(-(hashes * count).to_f / bits)) ** hashes) * 100
    puts <<-EOS
      Number of items in the filter (n):  #{count}
      Probability of false positives (p): #{fp_probability}
      Number of bits in the filter (m):   #{bits}
      Number of hash functions (k):       #{hashes}
      Predicted false positive rate:      #{fp.round(2)}
    EOS
  end

  private def calculate_bits
    (-(capacity * Math.log(fp_probability)) / (Math.log(2) ** 2)).round.to_i32
  end

  private def indexes_for(string)
    hashes.times.map { |i| CRC32.checksum("#{string}:#{i + seed}") % bits }
  end
end
