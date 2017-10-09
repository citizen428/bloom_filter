require "set"
require "./spec_helper"

private def basic_test
  b = BloomFilter.new(10_000)
  b.add("a").should be_true
  b.count.should eq 1
  b.add("a").should be_false
  b.should contain("a")
  b.should_not contain("")
  b.should_not contain("b")
  b.add("b").should be_true
  b.count.should eq 2
  b.add("b").should be_false
  b.should contain("b")
  b.should_not contain("")
  b.add("")
  b.should contain("")
  b.count.should eq 3
end

private def bulk_add_test
  b = BloomFilter.new(10_000)
  b.add_from(["a", "b"]).should be_true
  b.count.should eq 2
  b.should contain("a")
  b.should contain("b")
  b.add_from(["a", "b"]).should be_false
  b.add_from(["c"]).should be_true
end

ALPHABET = ('a'..'z').to_a

private def rand_word(length = 8)
  ALPHABET.shuffle.first(length).join # not random enough to cause hits.
end

alias Filter = BloomFilter | BloomFilter::Scalable

private def error_rate_test(filter : Filter, capacity : Int32, max_error_rate : Float64)
  set = Set(String).new
  capacity.times do
    word = rand_word
    set.add(word)
    filter.add(word)
  end

  # Check that all words are in the filter
  set.each { |word| filter.should contain(word) }

  tries = capacity * 3
  false_hits = 0
  hits = 0
  tries.times.each do
    word = rand_word
    filter_includes, set_includes = filter.includes?(word), set.includes?(word)
    hits += 1 if set_includes
    if set_includes && !filter_includes
      fail "'#{word}': false negative on include"
    elsif !set_includes && filter_includes
      false_hits += 1
    end
  end

  fp_rate = false_hits.to_f / tries
  if (fp_rate) > max_error_rate * 2
    fail "False-positive failure rate was bad: #{fp_rate}"
  end
end

describe BloomFilter do
  it "works" do
    basic_test
  end

  it "can buld add items" do
    bulk_add_test
  end

  it "has the expected error rate" do
    capacity = 10_000
    error_probability = 0.001
    filter = BloomFilter.new(capacity, error_probability)
    error_rate_test(filter, capacity, error_probability)
  end
end

describe BloomFilter::Scalable do
  it "works like a normal BloomFilter" do
    basic_test
  end

  it "can buld add items" do
    bulk_add_test
  end

  it "has the expected error rate" do
    capacity = 10_000
    error_probability = 0.001
    filter = BloomFilter::Scalable.new(capacity, error_probability)
    error_rate_test(filter, capacity, error_probability)
  end

  it "can grow as needed" do
    b = BloomFilter::Scalable.new(10)
    b.capacity.should eq 10
    20.times { |i| b.add("word#{i}") }
    b.capacity.should eq 20
  end
end
