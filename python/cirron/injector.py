import os
import tempfile
import subprocess
import time
from collections import namedtuple

Rule = namedtuple("Rule", ["syscall", "action", "value", "when"])


class Injector:
    VALID_ACTIONS = {
        "error",
        "retval",
        "signal",
        "syscall",
        "delay_enter",
        "delay_exit",
        "poke_enter",
        "poke_exit",
        "when",
    }

    def __init__(self):
        self.rules = []

    def add_rule(self, syscall, action, value, when=None):
        if action not in self.VALID_ACTIONS:
            raise ValueError(
                f"Invalid action: {action}. Valid actions are: {', '.join(self.VALID_ACTIONS)}"
            )

        self.rules.append(Rule(syscall, action, value, when))

    def __enter__(self, timeout=10):
        parent_pid = os.getpid()
        self.trace_file = tempfile.mktemp()

        # Construct the strace command with injection rules
        cmd = [
            "strace",
            "--quiet=attach,exit",
            "-f",
            "-o",
            self.trace_file,
            "-p",
            str(parent_pid),
        ]

        for rule in self.rules:
            inject_arg = f"inject={rule.syscall}:{rule.action}={rule.value}"
            if rule.when:
                inject_arg += f":when={rule.when}"
            cmd.extend(["-e", inject_arg])

        self._strace_proc = subprocess.Popen(cmd)

        deadline = time.monotonic() + timeout
        while not os.path.exists(self.trace_file):
            if time.monotonic() > deadline:
                raise TimeoutError(f"Failed to start strace within {timeout}s.")
        time.sleep(0.1)

        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self._strace_proc.terminate()
        self._strace_proc.wait()

        os.unlink(self.trace_file)
