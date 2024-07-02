import unittest
import os

from cirron import Tracer, Collector


class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            print(0)

        self.assertEqual(len(t.trace), 3)

    @unittest.skipIf(
        "GITHUB_ACTIONS" in os.environ,
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector(self):
        with Collector() as c:
            print(0)

        self.assertGreater(c.counters.time_enabled_ns, 0)
