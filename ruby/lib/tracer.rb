require 'tempfile'
require 'json'

class Syscall
  attr_reader :name, :args, :retval, :duration, :timestamp, :pid

  def initialize(name:, args:, retval:, duration:, timestamp:, pid:)
    @name = name
    @args = args
    @retval = retval
    @duration = duration
    @timestamp = timestamp
    @pid = pid
  end

  def to_s
    "#{name}(#{args}) = #{retval} <#{duration}s>"
  end
end

class TraceSignal
  attr_reader :name, :details, :timestamp, :pid

  def initialize(name:, details:, timestamp:, pid:)
    @name = name
    @details = details
    @timestamp = timestamp
    @pid = pid
  end

  def to_s
    "#{name} {#{details}}"
  end
end

def parse_strace(file)
  syscall_pattern = /^(\d+) +(\d+\.\d+) (\w+)\((.*?)\) += +(.*?) <(.*?)>$/
  signal_pattern = /^(\d+) +(\d+\.\d+) --- (\w+) {(.*)} ---$/
  unfinished_pattern = /^(\d+) +(\d+\.\d+) (\w+)\((.*?) +<unfinished \.\.\.>$/
  resumed_pattern = /^(\d+) +(\d+\.\d+) <\.\.\. (\w+) resumed>(.*?)?\) += +(.*?) <(.*?)>$/

  result = []
  unfinished_syscalls = {}

  file.each_line do |line|
    case line
    when syscall_pattern
      pid, timestamp, syscall, args, retval, duration = $~.captures
      result << Syscall.new(name: syscall, args: args, retval: retval, duration: duration, timestamp: timestamp, pid: pid)
    when signal_pattern
      pid, timestamp, signal, details = $~.captures
      result << TraceSignal.new(name: signal, details: details, timestamp: timestamp, pid: pid)
    when unfinished_pattern
      pid, timestamp, syscall, args = $~.captures
      key = [pid, syscall]
      unfinished_syscalls[key] ||= []
      unfinished_syscalls[key] << [timestamp, args]
    when resumed_pattern
      pid, timestamp, syscall, args2, retval, duration = $~.captures
      key = [pid, syscall]
      if unfinished_syscalls[key]&.any?
        start_timestamp, args = unfinished_syscalls[key].pop
        result << Syscall.new(name: syscall, args: "#{args}#{args2}", retval: retval, duration: duration, timestamp: start_timestamp, pid: pid)
      else
        puts "Resumed syscall without a start: #{line}"
      end
    else
      puts "Attempted to parse unrecognized strace line: #{line}"
    end
  end

  result
end

def filter_trace(trace, marker_path)
  start_index = trace.index { |event| event.is_a?(Syscall) && event.args.include?(marker_path) }
  end_index = trace.rindex { |event| event.is_a?(Syscall) && event.args.include?(marker_path) }

  if start_index && end_index
    trace[start_index + 1...end_index]
  else
    puts "Failed to find start and end markers for the trace, returning the full trace."
    trace
  end
end

module Cirron
  def self.tracer(timeout = 10, &block)
    trace_file = Tempfile.new('cirron')
    trace_file.close
    parent_pid = Process.pid
    cmd = "strace --quiet=attach,exit -f -T -ttt -o #{trace_file.path} -p #{parent_pid}"
    
    strace_proc = spawn(cmd, :out => "/dev/null", :err => "/dev/null")
    
    # Wait for the trace file to be created
    deadline = Time.now + timeout
    begin
      until File.exist?(trace_file.path)
        if Time.now > deadline
          raise Timeout::Error, "Failed to start strace within #{timeout}s."
        end
      end
      # :(
      sleep 0.1

      # We use this dummy fstat to recognize when we start executing the block
      File.stat(trace_file.path + ".dummy") rescue nil

      yield if block_given?

      # Same here, to recognize when we're done executing the block
      File.stat(trace_file.path + ".dummy") rescue nil
    ensure
      Process.kill('INT', strace_proc) rescue nil
      Process.wait(strace_proc) rescue nil
    end

    # Parse the trace file into a list of events
    trace = File.open(trace_file.path, 'r') do |file|
      parse_strace(file)
    end

    trace = filter_trace(trace, trace_file.path + ".dummy")

    trace_file.unlink

    trace
  end

  def self.to_tef(parsed_events)
    events = parsed_events.map do |event|
      case event
      when Syscall
        start_ts = event.timestamp.to_f * 1_000_000
        duration_us = event.duration.to_f * 1_000_000
        {
          name: event.name,
          ph: "X",
          ts: start_ts,
          dur: duration_us,
          pid: event.pid.to_i,
          tid: event.pid.to_i,
          args: { args: event.args, retval: event.retval }
        }
      when TraceSignal
        ts = event.timestamp.to_f * 1_000_000
        {
          name: "Signal: #{event.name}",
          ph: "i",
          s: "g",
          ts: ts,
          pid: event.pid.to_i,
          tid: event.pid.to_i,
          args: { details: event.details }
        }
      end
    end

    JSON.pretty_generate(events)
  end
end