import unittest
import os
import time
import errno

from cirron import Tracer, Collector, Injector

# GITHUB_ACTIONS "should" be defined, but turns out it's not.
IN_GITHUB_ACTIONS = os.getenv("POWERSHELL_DISTRIBUTION_CHANNEL") and os.getenv(
    "POWERSHELL_DISTRIBUTION_CHANNEL"
).startswith("GitHub")


class TestTracer(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            time.sleep(0.1)

        self.assertEqual(len(t.trace), 1)


class TestCollector(unittest.TestCase):
    @unittest.skipIf(
        IN_GITHUB_ACTIONS,
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector(self):
        with Collector() as c:
            time.sleep(0.1)

        self.assertGreater(c.counters.instruction_count, 0)

    @unittest.skipIf(
        IN_GITHUB_ACTIONS,
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector_empty(self):
        # The collector should remove overhead from the measurements,
        # so this should theoretically be 0. This may be flaky.
        with Collector() as c:
            pass

        self.assertEqual(c.counters.instruction_count, 0)


class TestInjector(unittest.TestCase):
    def test_injector(self):
        injector = Injector()
        injector.add_rule("openat", "error", "ENOSPC")
        with injector:
            with self.assertRaises(OSError) as cm:
                f = open("test.txt", "w")

            # Check if the error code matches ENOSPC
            self.assertEqual(cm.exception.errno, errno.ENOSPC)
            # Optionally, check the error message
            self.assertIn("No space left on device", str(cm.exception))
