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
        self.python_pack_dir = os.path.join(self.project_root_dir, self.pname)

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
                'fabfile': self.env.get_template('fabfile.tpl'),
                'init': self.env.get_template('init.tpl'),
                'app': self.env.get_template('app.tpl'),
                'tools': self.env.get_template('tools.tpl'),
                'handler_base': self.env.get_template('handler_base.tpl'),
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
        # prepare to write this result to README.md
        tools.write_file(_path, render_result)
        logger.info('Generate README.md.')

    def gen_tests(self):
        os.mkdir(os.path.join(self.project_root_dir, 'tests'))
        logger.info('Generate tests directory.')

    def gen_requirements(self):
        # Empty file considering the version.
        _path = os.path.join(self.project_root_dir, 'requirements.txt')
        tools.write_file(_path, '')
        logger.info('Generate requirements file.')

    def gen_fabfile(self):
        _path = os.path.join(self.project_root_dir, 'fabfile.py')
        # prepare to render confs
        render_result = self.templates['fabfile'].render()
        tools.write_file(_path, render_result)
        logger.info('Generate fabfile.')

    def gen_python_package(self):
        os.mkdir(self.python_pack_dir)
        # create __init__.py
        render_result = self.templates['init'].render()
        tools.write_file(os.path.join(self.python_pack_dir, '__init__.py'), render_result)
        logger.info('Generate python package.')

    def gen_app(self):
        render_result = self.templates['app'].render()
        tools.write_file(os.path.join(self.python_pack_dir, 'app.py'), render_result)
        logger.info('Generate app.py.')

    def gen_tools(self):
        render_result = self.templates['tools'].render()
        tools.write_file(os.path.join(self.python_pack_dir, 'tools.py'), render_result)
        logger.info('Generate tools.py.')

    def gen_handlers(self):
        _handlers_path = os.path.join(self.python_pack_dir, 'handlers')
        os.mkdir(_handlers_path)
        # create __init__.py
        render_result = self.templates['init'].render()
        tools.write_file(os.path.join(_handlers_path, '__init__.py'), render_result)
        # create base handler
        _base_handler_path = os.path.join(_handlers_path, 'base.py')
        render_result = self.templates['handler_base'].render()
        tools.write_file(_base_handler_path, render_result)
        logger.info('Generate handlers.')

    def gen_models(self):
        pass

    def gen_exceptions(self):
        pass

    def gen_log(self):
        pass

    def gen_consts(self):
        pass
