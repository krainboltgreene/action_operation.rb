require "benchmark/ips"
require "scrawl"
require "scrolls"
require "logger"
require "securerandom"

DATA = (1..100).map { |i| { SecureRandom.hex.to_s => SecureRandom.hex.to_s } }.inject(:merge!)

Scrolls.stream = File.open(File.join("tmp", "scrolls.log"), "w")
scrawl_logger = Logger.new(File.join("tmp", "scrawl.log"))

Benchmark.ips do |x|
  x.report "scrawl" do
    o = Scrawl.new(DATA.dup)
    scrawl_logger.log(0, o.inspect)
  end

  x.report "scrolls" do
    Scrolls.log(DATA.dup)
  end
end
