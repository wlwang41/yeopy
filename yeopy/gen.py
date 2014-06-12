#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import sys

from jinja2 import (
    Environment, FileSystemLoader, TemplateError
)

from yeopy import tools

logger = logging.getLogger(__name__)
# os.getcwd()


class Generator(object):

    def __init__(self, pname):
        self.pname = pname
        self.user_dir = os.getcwd()

        try:
            # jinja2
            # 没有找到具体html的路径
            self.env = Environment(
                loader=FileSystemLoader(
                    os.path.join(os.path.dirname(__file__), 'templates')
                )
            )
        except TemplateError, e:
            logging.error(str(e))
            sys.exit(1)

    def gen_root_dir(self, path):
        os.mkdir(os.path.join(self.user_dir, self.pname))

    def gen_app():
        pass

    def gen_tools():
        pass

    def gen_handlers():
        pass

    def gen_models():
        pass

    def gen_controlers():
        pass

    def gen_exceptions():
        pass

    def gen_log():
        pass

    def gen_consts():
        pass

    def gen_readme():
        pass

    def gen_tests():
        pass

    def gen_requirements():
        pass

    def gen_fabfile(self):
        pass
