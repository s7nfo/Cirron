require_relative 'lib/cirron'

collector = Cirron.collector do
  puts "Hello"
end

puts collector.counters

