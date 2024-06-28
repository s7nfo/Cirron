require 'ffi'

module CirronInterOp 
  extend FFI::Library

  ffi_lib './cirronlib.so'
  attach_function :start, [], :int
  attach_function :end, [:int, :pointer], :int
end

class Counter < FFI::Struct
  layout :time_enabled_ns, :long_double,
         :instruction_count, :long_double,
         :branch_misses, :long_double,
         :page_faults, :long_double
end

module CounterLib
  def self.start
    ret_val = CirronInternOp.start
    if ret_val == -1
      raise "Failed to start collector"
    end
    ret_val
  end

  def self.end(fd, counter)
    CirronInternOp.end(fd, counter)
  end

  def self.collector(&blk)
    counter = Counter.new
    ret_val = self.start

    yield

    self.end(ret_val, counter)
    counter
  end
end