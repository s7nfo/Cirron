import unittest
import os

from cirron import Tracer, Collector


class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            with open("/tmp/test", "w") as f:
                f.write("test")

        print(t.trace)
        self.assertEqual(len(t.trace), 9)

    @unittest.skipIf(
        os.getenv("POWERSHELL_DISTRIBUTION_CHANNEL")
        and os.getenv("POWERSHELL_DISTRIBUTION_CHANNEL").startswith(
            "GitHub"
        ),  # GITHUB_ACTIONS "should" be defined, but turns out it's not.
        "As of 02/07/2024, GitHub Actions does not support perf_event_open.",
    )
    def test_collector(self):
        with Collector() as c:
            print(0)

        print(c.counters)
        self.assertGreater(c.counters.instruction_count, 0)
