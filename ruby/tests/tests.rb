require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

class TestCirron < Minitest::Test
  def test_tracer
    trace = Cirron::tracer do
      sleep 0.1
    end

    assert_equal 3, trace.size
  end

  def test_collector
    if ENV['POWERSHELL_DISTRIBUTION_CHANNEL']&.start_with?('GitHub')
      skip 'As of 02/07/2024, GitHub Actions does not support perf_event_open.'
    end

    counters = Cirron::collector do
      puts 0
    end

    assert_operator counters[:instruction_count], :>, 0
  end
end