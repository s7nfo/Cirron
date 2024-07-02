import unittest
import os

from cirron import Tracer, Collector


class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            print(0)
        print(t.trace)

        self.assertEqual(len(t.trace), 3)

    @unittest.skipIf(
        os.getenv("GITHUB_ACTIONS") == "true",
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector(self):
        print(os.environ)
        with Collector() as c:
            print(0)

        self.assertGreater(c.counters.time_enabled_ns, 0)
