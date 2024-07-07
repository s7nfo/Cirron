require 'ffi'

module CirronInterOp
  extend FFI::Library

  lib_path = File.join(__dir__, 'cirronlib.so')
  source_path = File.join(__dir__, 'cirronlib.cpp')

  unless File.exist?(lib_path)
    exit_status = system("c++ -std=c++17 -O3 -shared -fPIC -o #{lib_path} #{source_path}")
    if exit_status.nil? || !exit_status
      raise "Failed to compile cirronlib.cpp, make sure you have 'c++' installed."
    end
  end

  ffi_lib lib_path
  attach_function :start, [], :int
  attach_function :end, [:int, :pointer], :int
end

class Counter < FFI::Struct
  layout :time_enabled_ns, :uint64,
         :instruction_count, :uint64,
         :branch_misses, :uint64,
         :page_faults, :uint64

  def self.create_accessors
    layout.members.each do |field|
      define_method(field) { self[field] }
      define_method("#{field}=") { |value| self[field] = value }
    end
  end

  create_accessors

  def to_s
    inspect
  end

  def inspect
    fields = self.class.layout.members.map do |field|
      "#{field}: #{self[field]}"
    end
    "Counter(#{fields.join(', ')})"
  end
end

module Cirron
  @overhead = {}

  def self.calculate_overhead
    puts "Measuring overhead..."
    10.times do
      counter = collector(measure_overhead: false) {}
      Counter.members.each do |field|
        @overhead[field] = [@overhead[field], counter[field]].compact.min
      end
    end
    puts @overhead
  end

  def self.start
    ret_val = CirronInterOp.start
    if ret_val == -1
      raise "Failed to start collector"
    end
    ret_val
  end

  def self.end(fd, counter)
    CirronInterOp.end(fd, counter)
  end

  def self.collector(measure_overhead: true, &blk)
    calculate_overhead if measure_overhead && @overhead.empty?

    counter = Counter.new
    ret_val = self.start

    yield

    self.end(ret_val, counter)

    if measure_overhead && !@overhead.empty?
      Counter.members.each do |field|
        counter[field] = [counter[field] - @overhead[field], 0].max
      end
    end

    counter
  end
end