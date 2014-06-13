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
        self.project_root_dir = os.path.join(self.user_dir, pname)

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

    def gen_root_dir(self):
        os.mkdir(os.path.join(self.user_dir, self.pname))

    def gen_readme(self):
        template = self.env.get_template('readme.tpl')

    def gen_tests(self):
        pass

    def gen_requirements(self):
        pass

    def gen_fabfile(self):
        pass

    def gen_app(self):
        pass

    def gen_tools(self):
        pass

    def gen_handlers(self):
        pass

    def gen_models(self):
        pass

    def gen_controlers(self):
        pass

    def gen_exceptions(self):
        pass

    def gen_log(self):
        pass

    def gen_consts(self):
        pass
