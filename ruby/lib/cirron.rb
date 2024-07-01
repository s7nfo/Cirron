require_relative 'tracer'
require_relative 'collector'

if FILE == $0
  puts "Testing Tracer class..."
  tracer = Tracer.trace do
    puts "Hello, World!"
    sleep(0.1)
  end
  puts "Trace completed. First 5 events:"
  puts tracer.trace.first(5)
  puts "Test completed."
end
puts "Tracer class loaded successfully."