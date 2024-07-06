# Cirron

Cirron measures a piece of Python or Ruby code and report back several performance counters: CPU instruction count, branch misses, page faults and time spent measuring. It uses the Linux perf events interface or @ibireme's [KPC demo](https://gist.github.com/ibireme/173517c208c7dc333ba962c1f0d67d12) on OSX.

It can also trace syscalls using `strace`, Linux only!

## Prerequisites

- Linux with perf events support / Apple ARM OSX
- C++
- Python 3.x / Ruby 3.x

## Installation

### Python
```bash
pip install cirron
```

### Ruby
```bash
gem install cirron
```

The wrapper automatically compiles the C++ library (cirronlib.cpp) on first use.

## Usage

### Performance Counters

#### Python

```
$ sudo python
>>> from cirron import Collector
>>> 
>>> # Start collecting performance metrics
>>> with Collector() as collector:
>>>     # Your code here
>>>     # ...
>>> 
>>> # Retrieve the metrics
>>> print(collector.counters)
```

#### Ruby

```
$ sudo irb
irb(main):001> require 'cirron'
=> true
irb(main):002* c = Cirron::collector do
irb(main):003*   puts 1
irb(main):004> end
1
=> #<Counter:0x0000000128a53498>
irb(main):005> c[:instruction_count]
=> 0.0
```

### Syscalls
```
from cirron import Tracer, to_tef

with Tracer() as tracer:
    # Your code here
    # ...

# Stop collecting and retrieve the trace
print(tracer.trace)

# Save the trace for ingesting to Perfetto
open("/tmp/trace", "w").write(to_tef(trace))
```
