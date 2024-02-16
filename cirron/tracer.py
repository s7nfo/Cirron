import tempfile
import os
import subprocess
import re
import json
from dataclasses import dataclass


def to_tef(parsed_events):
    events = []
    for event in parsed_events:
        if type(event) == Syscall:
            start_ts = float(event.timestamp) * 1_000_000
            duration_us = float(event.duration) * 1_000_000
            events.append(
                {
                    "name": event.name,
                    "ph": "X",
                    "ts": start_ts,
                    "dur": duration_us,
                    "pid": int(event.pid),
                    "tid": int(event.pid),
                    "args": {"args": event.args, "retval": event.retval},
                }
            )
        elif type(event) == Signal:
            ts = float(event.timestamp) * 1_000_000
            events.append(
                {
                    "name": f"Signal: {event.name}",
                    "ph": "i",
                    "s": "g",
                    "ts": ts,
                    "pid": int(event.pid),
                    "tid": int(event.pid),
                    "args": {"details": event.details},
                }
            )

    tef_json = json.dumps(events, indent=2)
    return tef_json


@dataclass
class Syscall:
    name: str
    args: str
    retval: str
    duration: str
    timestamp: str
    pid: str

    def __str__(self):
        return f"{self.name}({self.args}) = {self.retval} <{self.duration}s>"


@dataclass
class Signal:
    name: str
    details: str
    timestamp: str
    pid: str

    def __str__(self):
        return f"{self.name} {{{self.details}}}"


def parse_strace(f):
    syscall_pattern = re.compile(r"^(\d+) (\d+\.\d+) (\w+)\((.*?)\) += +(.*?) <(.*?)>$")
    signal_pattern = re.compile(r"^(\d+) (\d+\.\d+) --- (\w+) {(.*)} ---$")
    unfinished_pattern = re.compile(
        r"^(\d+) (\d+\.\d+) (\w+)\((.*?) +<unfinished \.\.\.>$"
    )
    resumed_pattern = re.compile(
        r"^(\d+) (\d+\.\d+) <\.\.\. (\w+) resumed>(.*?)?\) += +(.*?) <(.*?)>$"
    )

    result = []
    unfinished_syscalls = {}

    for line in f:
        if match := syscall_pattern.match(line):
            pid, timestamp, syscall, args, retval, duration = match.groups()
            result.append(
                Syscall(
                    name=syscall,
                    args=args,
                    retval=retval,
                    duration=duration,
                    timestamp=timestamp,
                    pid=pid,
                )
            )
        elif match := signal_pattern.match(line):
            pid, timestamp, signal, details = match.groups()
            result.append(
                Signal(
                    name=signal,
                    details=details,
                    timestamp=timestamp,
                    pid=pid,
                )
            )
        elif match := unfinished_pattern.match(line):
            pid, timestamp, syscall, args = match.groups()
            key = (pid, syscall)
            if key not in unfinished_syscalls:
                unfinished_syscalls[key] = []
            unfinished_syscalls[key].append((timestamp, args))
        elif match := resumed_pattern.match(line):
            pid, timestamp, syscall, args2, retval, duration = match.groups()
            key = (pid, syscall)
            if key in unfinished_syscalls and unfinished_syscalls[key]:
                start_timestamp, args = unfinished_syscalls[key].pop()
                result.append(
                    Syscall(
                        name=syscall,
                        args=args + args2,
                        retval=retval,
                        duration=duration,
                        timestamp=start_timestamp,
                        pid=pid,
                    )
                )
            else:
                print(f"Resumed syscall without a start: {line}")
        else:
            print(f"Attempted to parse unrecognized strace line: {line}")

    return result


class Tracer:
    def start(self):
        parent_pid = os.getpid()
        self.trace_file = tempfile.mktemp()

        cmd = f"strace --quiet=attach,exit -f -T -ttt -o {self.trace_file} -p {parent_pid}".split()
        self.strace_proc = subprocess.Popen(cmd)

        while not os.path.exists(self.trace_file):
            pass

    def stop(self):
        self.strace_proc.terminate()
        self.strace_proc.wait()

        with open(self.trace_file, "r") as f:
            parsed_output = parse_strace(f)

        os.unlink(self.trace_file)

        return parsed_output
