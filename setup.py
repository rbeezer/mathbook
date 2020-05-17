import os
from setuptools import setup, find_packages
from glob import glob

with open("README.md", "r") as fh:
    long_description = fh.read()

# This directory
dir_setup = os.path.dirname(os.path.realpath(__file__))

with open(os.path.join(dir_setup, "script", "version.py")) as f:
    # Defines __version__
    exec(f.read())


# Non-Python deps
#   - TODO: Not sure about conventions...
#   - TODO: but nice to list dependencies somewhere


setup(
    name="PreTeXt-utils",
    version=__version__,
    description="Utilities for processing PreTeXt files",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://pretextbook.org",
    author="Rob Beezer",
    license="GPLv2, GPLv3",  # TODO: check license
    python_requires=">=3.4",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: GNU General Public License v2 or GNU General Public License v3",
        "Development Status :: 3 - Alpha",
        "Operating System :: OS Independent",
        "Topic :: Text Processing",
    ],
    entry_points={
        "console_scripts": [
            "pretext-mbx=script.mbx:main",
        ],
    },
    include_package_data=True,
    data_files=[
        (
            "share/pretext/schema",
            [
                "schema/pretext.xml",
                "schema/README.md",
            ],
        ),
        (
            "share/pretext/xsl",
            [
                "xsl/mathbook-common.xsl",
                "xsl/mathbook-html.xsl",
                "xsl/entities.ent",
            ],

        ),
    ],
    install_requires = [
        "Pillow",
    ],
)
