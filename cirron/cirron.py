from ctypes import (
    Structure,
    byref,
    c_uint64,
    c_int,
    POINTER,
    CDLL,
)
from pkg_resources import resource_filename
import os
from subprocess import call


class Counter(Structure):
    _fields_ = [
        ("instruction_count", c_uint64),
        ("time_enabled_ns", c_uint64),
    ]

    def __str__(self):
        return f"Counter(instruction_count={self.instruction_count}, time_enabled_ns={self.time_enabled_ns})"

    def __repr__(self):
        return f"Counter(instruction_count={self.instruction_count}, time_enabled_ns={self.time_enabled_ns})"


lib_path = resource_filename(__name__, "cirronlib.so")
if not os.path.exists(lib_path):
    source_path = resource_filename(__name__, "cirronlib.c")
    exit_status = call(f"gcc -shared -fPIC -o {lib_path} {source_path}", shell=True)
    if exit_status != 0:
        raise Exception(
            "Failed to compile cirronlib.c, make sure you have gcc installed."
        )

cirron_lib = CDLL(lib_path)
cirron_lib.start.argtypes = None
cirron_lib.start.restype = c_int
cirron_lib.end.argtypes = [c_int, POINTER(Counter)]
cirron_lib.end.restype = None


class Collector:
    def __init__(self):
        self.fd = None
        self.counter = Counter()

    def start(self):
        ret_val = cirron_lib.start()
        if ret_val == -1:
            raise Exception("Failed to start collector.")
        self.fd = ret_val

    def end(self):
        ret_val = cirron_lib.end(self.fd, byref(self.counter))
        if ret_val == -1:
            raise Exception("Failed to end collector.")
        return self.counter
