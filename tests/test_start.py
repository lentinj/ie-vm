import os
import subprocess
import unittest

SHELLS = ['/bin/dash', '/bin/bash']

class TestStartSh(unittest.TestCase):
    def setUp(self):
        open('ut_newest.qcow2', 'a').close()

    def tearDown(self):
        os.remove('ut_newest.qcow2')

    def test_imageArgument(self):
        out = self.run_start([])
        self.assertRegex(out, r'-drive file=ut_newest.qcow2')

        out = self.run_start(["camel.qcow2"])
        self.assertRegex(out, r'-drive file=camel.qcow2')

    def run_start(self, extra_args):
        """Run script through several shells"""
        output = None
        for sh in SHELLS:
            shOut = subprocess.check_output([
                sh,
                "./start.sh",
                "--qemu-bin", "/bin/echo",
            ] + extra_args)
            if output:
                self.assertEqual(shOut, output)
            else:
                output = shOut
        return shOut.decode('utf8')

if __name__ == '__main__':
    unittest.main()
