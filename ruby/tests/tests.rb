require 'minitest/autorun'
require 'tempfile'
require_relative '../lib/cirron'

class TestCirron < Minitest::Test
  def test_tracer
    t = Cirron::Tracer.trace do
      Tempfile.create('test') do |f|
        puts "block\n"
        f.write('test')
        sleep 0.1
      end
    end

    puts t
    assert_equal 4, t.size
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