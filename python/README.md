# Cirron

Cirron measures a piece of Python code and report back several performance counters: CPU instruction count, branch misses, page faults and time spent measuring. It uses the Linux perf events interface or @ibireme's [KPC demo](https://gist.github.com/ibireme/173517c208c7dc333ba962c1f0d67d12) on OSX.

It can also trace and modify syscalls using `strace`, Linux only!

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

### Tracing Syscalls

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

### Tampering with Syscalls

Available tampering actions are:
`error`: Inject a fault with the specified errno.
`retval`: Inject a success with the specified return value.
`signal`: Deliver the specified signal on syscall entry.
`delay_enter`: Delay syscall entry by the specified time.
`delay_exit`: Delay syscall exit by the specified time.
`poke_enter`: Modify memory at argN on syscall entry.
`poke_exit`: Modify memory at argN on syscall exit.
`syscall`: Inject a different syscall instead.

The `when` argument can be used to specify when to perform the tampering.

See the Tampering section of the [strace manual page](https://man7.org/linux/man-pages/man1/strace.1.html) for more detailed explanaition of the arguments.

```
$ sudo python
>>> from cirron import Injector

>>> injector = Injector()
>>> injector.inject("openat", "error", "ENOSPC")
>>> injector.inject("openat", "delay_enter", "1s", when="2+2")
>>> with injector:
>>>     # Open now fails with "No space left on device" and every
>>>     # other call to `openat` will be delayed by 1s.
>>>     f = open("test.txt", "w")
```