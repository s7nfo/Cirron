# Cirron

Cirron measures a piece of Python code and report back several performance counters: CPU instruction count, branch misses, page faults and time spent measuring. It uses the Linux perf events interface.

## Prerequisites

- Linux with perf events support
- GCC
- Python 3.x

## Installation

Clone the repository:

```bash
git clone https://github.com/s7nfo/Cirron.git
pip install ./cirron
```

The Python wrapper automatically compiles the C library (cirronlib.c) on first use.

## Usage

```
from cirron import Collector

collector = Collector()

# Start collecting performance metrics
collector.start()

# Your code here
# ...

# Stop collecting and retrieve the metrics
metrics = collector.end()
print(metrics)
```
