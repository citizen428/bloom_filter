require "./spec_helper"

[BloomFilter, BloomFilter::Scalable].each do |klass|
  describe klass do
    it "works" do
      b = klass.new(10_000)
      b.add("a").should be_true
      b.count.should eq 1
      b.add("a").should be_false
      b.include?("a").should be_true
      b.include?("").should be_false
      b.include?("b").should be_false
      b.add("b").should be_true
      b.count.should eq 2
      b.add("b").should be_false
      b.include?("b").should be_true
      b.include?("").should be_false
      b.add("")
      b.include?("").should be_true
      b.count.should eq 3
    end
  end
end
