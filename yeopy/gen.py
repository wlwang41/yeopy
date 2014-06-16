#!/usr/bin/env python
# -*- coding: utf-8 -*-

import logging
import os
import sys

from jinja2 import (
    Environment, FileSystemLoader, TemplateError,
    # ChoiceLoader, PackageLoader
)

from yeopy import tools

logger = logging.getLogger(__name__)


class Generator(object):

    def __init__(self, pname):
        self.pname = pname
        self.user_dir = os.getcwd()
        self.project_root_dir = os.path.join(self.user_dir, pname)

        try:
            # self.env = Environment(loader=ChoiceLoader([
            #     FileSystemLoader('templates'),
            #     PackageLoader('yeopy', 'templates'),
            # ]))
            self.env = Environment(loader=FileSystemLoader(
                os.path.join(os.path.dirname(__file__), 'templates')
            ))

            self.templates = {
                'readme': self.env.get_template('readme.tpl'),
            }
        except TemplateError as e:
            logging.error(str(e))
            sys.exit(1)

    def gen_root_dir(self):
        if tools.check_path_exists(self.project_root_dir):
            logger.error('Path exist.')
            sys.exit(1)
        os.mkdir(self.project_root_dir)
        logger.info('Generate root directory.')

    def gen_readme(self):
        confs = {
            'pname': self.pname,
        }
        _path = os.path.join(self.project_root_dir, 'README.md')
        # prepare to render confs
        render_result = self.templates['readme'].render(confs)
        logger.debug('readme result: ' + render_result)
        # prepare to write this result to README.md
        tools.write_file(_path, render_result)
        logger.info('Generate README.md.')

    def gen_tests(self):
        os.mkdir(os.path.join(self.project_root_dir, 'tests'))
        logger.info('Generate tests directory.')

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
