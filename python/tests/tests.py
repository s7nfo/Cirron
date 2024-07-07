import unittest
import os
import time

from cirron import Tracer, Collector

# GITHUB_ACTIONS "should" be defined, but turns out it's not.
IN_GITHUB_ACTIONS = os.getenv("POWERSHELL_DISTRIBUTION_CHANNEL") and os.getenv(
    "POWERSHELL_DISTRIBUTION_CHANNEL"
).startswith("GitHub")


class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            time.sleep(0.1)

        self.assertEqual(len(t.trace), 1)

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
