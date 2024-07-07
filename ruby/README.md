= Cirron

Cirron measures a piece of Ruby code and reports back several performance counters: 
CPU instruction count, branch misses, page faults and time spent measuring. 
It uses the Linux perf events interface or @ibireme's KPC demo[https://gist.github.com/ibireme/173517c208c7dc333ba962c1f0d67d12] on OSX.

It can also trace syscalls using +strace+, Linux only!

== Prerequisites

  - Linux with perf events support / Apple ARM OSX
  - C++
  - Ruby 3.x

== Usage

=== Performance Counters
  $ sudo irb
  irb(main):001> require 'cirron'
  => true
  irb(main):002* c = Cirron::collector do
  irb(main):003*   puts "Hello"
  irb(main):004> end
  Hello
  => Counter(time_enabled_ns: 110260, instruction_count: 15406, branch_misses: 525, page_faults: 0)

=== Syscalls

  $ sudo irb
  irb> require 'cirron'
  => true
  irb> trace = Cirron::tracer do
  irb>  # Your code here
  irb>  puts "Hello"
  irb> end
  => [#<Syscall:0x00007c6c1a4b3608 @args="1, [{iov_base=\"Hello\", iov_len=5}, {iov_base=\"\\n\", iov_len=1}], 2", @duration="0.000201", @name="writev", @pid="2261962", @retval="6", @timestamp="1720285300.334976">]
  # Save the trace for ingesting to Perfetto
  irb> File.write("/tmp/trace", Cirron::to_tef(trace))
  => 267

== Additional Information

For more detailed information, please visit the project's GitHub page: https://github.com/s7nfo/Cirron