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
  layout :time_enabled_ns, :long_double,
         :instruction_count, :long_double,
         :branch_misses, :long_double,
         :page_faults, :long_double
end

module Cirron
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

  def self.collector(&blk)
    counter = Counter.new
    ret_val = self.start

    yield

    self.end(ret_val, counter)
    counter
  end
end