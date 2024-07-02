require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

class TestCirron < Minitest::Test
  def test_tracer
    t = Tracer.new
    t.trace do
      Tempfile.create('test') do |f|
        f.write('test')
      end
    end

    assert_equal 9, t.trace.size
  end

  def test_collector
    if ENV['POWERSHELL_DISTRIBUTION_CHANNEL']&.start_with?('GitHub')
      skip 'As of 02/07/2024, GitHub Actions does not support perf_event_open.'
    end

    c = Collector.new
    c.collect do
      puts 0
    end

    assert_operator c.counters.time_enabled_ns, :>, 0
  end
end