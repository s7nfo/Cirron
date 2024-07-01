import unittest
from cirron import Tracer, Collector

class Test(unittest.TestCase):
    def test_tracer(self):
        with Tracer() as t:
            print(0)
        
        self.assertEqual(len(t.trace), 3)

    def test_collector(self):
        with Collector() as c:
            print(0)
        
        self.assertGreater(c.counters.time_enabled_ns, 0)
