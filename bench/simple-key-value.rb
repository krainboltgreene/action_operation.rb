require "benchmark/ips"
require "scrawl"
require "scrolls"
require "securerandom"

DATA = (1..100).map { |i| { SecureRandom.hex.to_s => SecureRandom.hex.to_s } }.inject(:merge!)

Scrolls.stream = StringIO.new

Benchmark.ips do |x|
  x.report "scrawl" do
    o = Scrawl.new(DATA.dup)
    o.inspect
  end

  x.report "scrolls" do
    Scrolls.log(DATA.dup)
  end
end
