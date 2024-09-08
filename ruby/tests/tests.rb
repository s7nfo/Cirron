require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

IN_GITHUB_ACTIONS = ENV['POWERSHELL_DISTRIBUTION_CHANNEL']&.start_with?('GitHub')

class TestTracer < Minitest::Test
  def test_tracer
    trace = Cirron::tracer do
      sleep 0.1
    end

    assert_equal 3, trace.size
  end
end

class TestCollector < Minitest::Test
  def test_collector
    if IN_GITHUB_ACTIONS
      skip 'As of 02/07/2024, GitHub Actions does not support perf_event_open.'
    end

    counters = Cirron::collector do
      puts 0
    end

    assert_operator counters[:instruction_count], :>, 100
  end

  def test_collector_empty
    if IN_GITHUB_ACTIONS
      skip 'As of 02/07/2024, GitHub Actions does not support perf_event_open.'
    end

    counters = Cirron::collector {}

    # Unlike the Pyton implementation, the Ruby implementation does not
    # reduce the overhead to zero.
    assert_operator counters[:instruction_count], :<, 100
  end
end

class TestInjector < Minitest::Test
  def test_injector
    injector = Cirron.injector
    injector.add_rule("openat", "error", "ENOSPC")

    assert_raises(Errno::ENOSPC) do
      injector.run do
        File.open("test.txt", "w")
      end
    end
  end
end