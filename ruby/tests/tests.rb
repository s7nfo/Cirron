require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

IN_GITHUB_ACTIONS = ENV['POWERSHELL_DISTRIBUTION_CHANNEL']&.start_with?('GitHub')

class TestCirron < Minitest::Test
  def test_tracer
    trace = Cirron::tracer do
      sleep 0.1
    end

    assert_equal 3, trace.size
  end

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