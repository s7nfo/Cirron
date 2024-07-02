import unittest
import os

from cirron import Tracer, Collector


class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            with open("/tmp/test", "w") as f:
                f.write("test")

        self.assertEqual(len(t.trace), 9)

    @unittest.skipIf(
        os.getenv("POWERSHELL_DISTRIBUTION_CHANNEL").startswith(
            "GitHub"
        ),  # GITHUB_ACTIONS "should" be defined, but turns out it's not.
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector(self):
        print(os.environ)
        with Collector() as c:
            print(0)

        self.assertGreater(c.counters.time_enabled_ns, 0)
