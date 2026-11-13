"""Do not accept old, dirty, unsigned or incomplete OBS build results."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("obs_release", Path(__file__).resolve().parents[1] / "tools/obs-release.py")
obs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(obs)


class ObsTests(unittest.TestCase):
    def result(self, status="succeeded", dirty="", architectures=("x86_64", "i586")):
        return '<resultlist>' + ''.join(
            f'<result arch="{arch}" state="published" {dirty}>'
            f'<status package="elklock" code="{status}"/></result>' for arch in architectures
        ) + '</resultlist>'

    def test_completed_architectures(self):
        self.assertTrue(obs.builds_ready(self.result()))

    def test_dirty_success_is_stale(self):
        self.assertFalse(obs.builds_ready(self.result(dirty='dirty="true"')))

    def test_missing_architecture_is_not_ready(self):
        self.assertFalse(obs.builds_ready(self.result(architectures=("x86_64",))))

    def test_building_is_not_ready(self):
        self.assertFalse(obs.builds_ready(self.result(status="building")))

    def test_failure_is_explicit(self):
        with self.assertRaisesRegex(RuntimeError, "failed"):
            obs.builds_ready(self.result(status="failed"))

    def test_rpm_must_match_version_and_be_signed_by_obs(self):
        obs.validate_rpm_info("elklock\t0.1.0\tnoarch\tobs://build.opensuse.org/home:Agundur\tRSA/SHA256 signature\tobs://build.opensuse.org/home:Agundur/openSUSE_Tumbleweed/abc-elklock", "0.1.0", "abc")
        for info in (
            "elklock\t0.0.9\tnoarch\tobs://build.opensuse.org/home:Agundur\tRSA/SHA256 signature\tobs://build.opensuse.org/home:Agundur/openSUSE_Tumbleweed/abc-elklock",
            "elklock\t0.1.0\tnoarch\t(none)\t(none)\t(none)",
            "elklock\t0.1.0\tnoarch\tobs://build.opensuse.org/home:Agundur\tRSA/SHA256 signature\tobs://build.opensuse.org/home:Agundur/openSUSE_Tumbleweed/old-elklock",
        ):
            with self.assertRaises(ValueError):
                obs.validate_rpm_info(info, "0.1.0", "abc")


if __name__ == '__main__':
    unittest.main()
