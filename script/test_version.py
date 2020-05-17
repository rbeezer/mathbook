from packaging.version import Version
from .version import __version__


def test_valid_version():
    Version(__version__)
