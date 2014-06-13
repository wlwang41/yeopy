#!/usr/bin/env python

from setuptools import setup, find_packages
import yeopy


entry_points = {
    "console_scripts": [
        "yeopy = yeopy.cli:main",
    ]
}

# TODO(crow): requirements
requires = [
    "docopt",
    "jinja2",
]

setup(
    name="yeopy",
    version=yeopy.__version__,
    url="https://github.com/wlwang41/yeopy",
    author="Crow(wlwang41)",
    author_email="wlwang41@gmail.com",
    description="Yeopy is a scaffold for python web projects.",
    license="MIT License",
    packages=find_packages(),
    package_data={'yeopy': ['templates/*.tpl']},
    include_package_data=True,
    install_requires=requires,
    entry_points=entry_points,
)
