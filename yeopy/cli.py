#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Yeopy CLI

Usage:
  yeopy  init -p <project_name>
  yeopy  -h | --help
  yeopy  -V | --version

Options:
  -h, --help             Help information.
  -V, --version          Show version.
  -p <project_name>      The name of project.

"""

import logging

from docopt import docopt

from yeopy.log import logging_init
from yeopy import __version__
from yeopy.gen import Generator

logger = logging.getLogger(__name__)


def main():
    logging_init(logging.INFO)
    args = docopt(__doc__, version="yeopy {}".format(__version__))
    if args['init'] and args['-p']:
        logger.info('Init.')
        # prepare to generate files
        gen = Generator(args['-p'])
        gen.gen_root_dir()
        gen.gen_readme()
        gen.gen_tests()
        gen.gen_requirements()
        gen.gen_fabfile()
        logger.info('Done.')

if __name__ == '__main__':
    main()
