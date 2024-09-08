require 'tempfile'
require 'open3'

Rule = Struct.new(:syscall, :action, :value, :when)

module Cirron
  class Injector
    VALID_ACTIONS = [
        'error', 'retval', 'signal', 'syscall', 'delay_enter', 'delay_exit',
        'poke_enter', 'poke_exit', 'when'
      ].freeze

    def initialize
      @rules = []
    end

    def add_rule(syscall, action, value, when_condition = nil)
      unless VALID_ACTIONS.include?(action)
        raise ArgumentError, "Invalid action: #{action}. Valid actions are: #{VALID_ACTIONS.join(', ')}"
      end

      @rules << Rule.new(syscall, action, value, when_condition)
    end

    def run(timeout = 10)
      trace_file = Tempfile.new('cirron_inject')
      trace_file.close
      parent_pid = Process.pid

      cmd = ["strace", "--quiet=attach,exit", "-f", "-o", trace_file.path, "-p", parent_pid.to_s]

      @rules.each do |rule|
        inject_arg = "inject=#{rule.syscall}:#{rule.action}=#{rule.value}"
        inject_arg += ":when=#{rule.when}" if rule.when
        cmd.concat(["-e", inject_arg])
      end

      strace_proc = nil

      begin
        strace_proc = spawn(*cmd, :out => "/dev/null", :err => "/dev/null")

        deadline = Time.now + timeout
        until File.exist?(trace_file.path)
          if Time.now > deadline
            raise Timeout::Error, "Failed to start strace within #{timeout}s."
          end
          sleep 0.1
        end

        sleep 0.1

        yield if block_given?
      ensure
        Process.kill('INT', strace_proc) rescue nil
        Process.wait(strace_proc) rescue nil
        trace_file.unlink
      end
    end
  end

  def self.injector
    Injector.new
  end
end