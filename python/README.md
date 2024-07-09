# Cirron

Cirron measures a piece of Python code and report back several performance counters: CPU instruction count, branch misses, page faults and time spent measuring. It uses the Linux perf events interface or @ibireme's [KPC demo](https://gist.github.com/ibireme/173517c208c7dc333ba962c1f0d67d12) on OSX.

It can also trace syscalls using `strace`, Linux only!

## Prerequisites

- Linux with perf events support / Apple ARM OSX
- C++
- Python 3.x

## Installation

### Python

```bash
pip install cirron
```

The wrapper automatically compiles the C++ library (cirronlib.cpp) on first use.

## Usage

### Performance Counters

```
$ sudo python
>>> from cirron import Collector
>>> 
>>> # Start collecting performance metrics
>>> with Collector() as collector:
>>>     # Your code here
>>>     print("Hello")
>>> 
>>> # Retrieve the metrics
>>> print(collector.counters)
Counter(time_enabled_ns=144185, instruction_count=19434, branch_misses=440, page_faults=0)
```

### Syscalls

```
$ sudo python
>>> from cirron import Tracer, to_tef

>>> with Tracer() as tracer:
>>>     # Your code here
>>>     print("Hello")
>>> 
>>> # Retrieve the trace
>>> print(tracer.trace)
>>> [Syscall(name='write', args='1, "Hello\\n", 6', retval='6', duration='0.000043', timestamp='1720333364.368337', pid='2270837')]
>>> 
>>> # Save the trace for ingesting to Perfetto
>>> open("/tmp/trace", "w").write(to_tef(tracer.trace))
```