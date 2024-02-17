# Cirron

Cirron measures a piece of Python code and report back several performance counters: CPU instruction count, branch misses, page faults and time spent measuring. It uses the Linux perf events interface or @ibireme's [KPC demo](https://gist.github.com/ibireme/173517c208c7dc333ba962c1f0d67d12) on OSX.

It can also trace syscalls using `strace`, Linux only!

## Prerequisites

- Linux with perf events support / Apple ARM OSX
- C++
- Python 3.x

## Installation

Clone the repository:

```bash
git clone https://github.com/s7nfo/Cirron.git
pip install ./Cirron
```

The Python wrapper automatically compiles the C++ library (cirronlib.cpp) on first use.

## Usage

### Performance Counters
```
from cirron import Collector

# Start collecting performance metrics
with Collector() as collector:
    # Your code here
    # ...

# Retrieve the metrics
print(collector.counters)
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
