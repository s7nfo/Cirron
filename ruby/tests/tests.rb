require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

class TestCirron < Minitest::Test
  def test_tracer
    t = Cirron::Tracer.trace do
      Tempfile.create('test') do |f|
        f.write('test')
      end
    end

    assert_equal 10, t.size
  end

  def test_collector
    if ENV['POWERSHELL_DISTRIBUTION_CHANNEL']&.start_with?('GitHub')
      skip 'As of 02/07/2024, GitHub Actions does not support perf_event_open.'
    end

    c = Cirron::collector do
      puts 0
    end

    assert_operator c[:time_enabled_ns], :>, 0
  end
end