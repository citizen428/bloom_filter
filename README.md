# BloomFilter and BloomFilter::Scalable

[Bloom filters](http://en.wikipedia.org/wiki/Bloom_filter) for Crystal. Inspired by and based on [bloomer](https://github.com/mceachen/bloomer) by [Matthew McEachen](https://github.com/mceachen) and [bloomfilter-rb](https://github.com/igrigorik/bloomfilter-rb) by [Ilya Grigorik](https://github.com/igrigorik).

Bloom filters (`BloomFilter`) are space-efficient probabilistic data structures. They allow to quickly check if a given string has been seen before. There are no false negatives, but false positives are possible and their maximum probability can be specified. Bloom filters work in constant time and using constant memory, as long as the expected number of elements is known in advance. If this number is later exceeded, the accuracy will drop below the initally defined false positive probabiltiy. This implementation borrows Ilya Grigorik's CRC32-based hash implementation, so the same caveats apply.

> [T]his implementation seeds the CRC32 hash with k different initial values (0, 1, ..., k-1). This may or may not give you a good distribution, it all depends on the data.

The required number of hash functions is automatically calculated from the filter's capacity and the desired maximum false positive rate, see the [Bloom filter calculator](https://hur.st/bloomfilter) for details regarding the calculations.

Scalable Bloom filters (`BloomFilter::Scalable`) maintain a maximal false positive probability by increasing their memory usage as needed.

For ideas what to do with Bloom filters, check [Bloom Filters for the Perplexed](https://sagi.io/2017/07/bloom-filters-for-the-perplexed/) by [Sagi Kedmi](https://sagi.io).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  bloom_filter:
    github: citizen428/bloom_filter
```

## Usage

```crystal
require "bloom_filter"
b = BloomFilter.new(10000, 0.0001)
b.add("a")      #=> true
b.count         #=> 1
b.add("a")      #=> false
b.include?("a") #=> true
```

## Contributing

1. Fork it ( https://github.com/citizen428/bloom_filter/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [citizen428](https://github.com/citizen428) Michael Kohl - creator, maintainer
