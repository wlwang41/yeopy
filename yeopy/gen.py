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
            self.env = Environment(loader=FileSystemLoader(
                os.path.join(os.path.dirname(__file__), 'templates')
            ))

            self.templates = {
                'readme': self.env.get_template('readme.tpl'),
                'fabfile': self.env.get_template('fabfile.tpl'),
                'servers': self.env.get_template('servers.tpl'),
                'confs': self.env.get_template('confs.tpl'),
                'init': self.env.get_template('init.tpl'),
                'app': self.env.get_template('app.tpl'),
                'tools': self.env.get_template('tools.tpl'),
                'handler_base': self.env.get_template('handler_base.tpl'),
                'handler_init': self.env.get_template('handler_init.tpl'),
                'base_init': self.env.get_template('base_init.tpl'),
                'exc': self.env.get_template('exc.tpl'),
                'log': self.env.get_template('log.tpl'),
                'consts': self.env.get_template('consts.tpl'),
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

    def gen_deploy(self):
        _deploy_path = os.path.join(self.project_root_dir, 'deploy')

        os.mkdir(_deploy_path)

        # create __init__.py
        render_result = self.templates['init'].render()
        tools.write_file(os.path.join(_deploy_path, '__init__.py'), render_result)

        # create servers
        _servers_path = os.path.join(_deploy_path, 'servers.py')
        render_result = self.templates['servers'].render()
        tools.write_file(_servers_path, render_result)

        # create confs
        confs = {
            'pname': self.pname,
        }
        _confs_path = os.path.join(_deploy_path, 'confs.py')
        render_result = self.templates['confs'].render(confs)
        tools.write_file(_confs_path, render_result)

        logger.info('Generate handlers.')

    def gen_python_package(self):
        os.mkdir(self.python_pack_dir)

        # create __init__.py
        render_result = self.templates['init'].render()
        tools.write_file(os.path.join(self.python_pack_dir, '__init__.py'), render_result)

        logger.info('Generate python package.')

    def gen_app(self):
        confs = {
            'pname': self.pname,
        }
        render_result = self.templates['app'].render(confs)
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
        render_result = self.templates['handler_init'].render()
        tools.write_file(os.path.join(_handlers_path, '__init__.py'), render_result)

        # create base handler
        confs = {
            'pexc': self.pname.title() + 'Exception',
        }
        _base_handler_path = os.path.join(_handlers_path, 'base.py')
        render_result = self.templates['handler_base'].render(confs)
        tools.write_file(_base_handler_path, render_result)

        logger.info('Generate handlers.')

    def gen_models(self):
        confs = {
            'pexc': self.pname.title() + 'Exception',
        }
        _models_path = os.path.join(self.python_pack_dir, 'models')
        os.mkdir(_models_path)

        # create __init__.py
        render_result = self.templates['base_init'].render(confs)
        tools.write_file(os.path.join(_models_path, '__init__.py'), render_result)

        logger.info('Generate models.')

    def gen_exceptions(self):
        confs = {
            'pexc': self.pname.title() + 'Exception',
        }
        _exc_path = os.path.join(self.python_pack_dir, 'exc.py')
        render_result = self.templates['exc'].render(confs)
        tools.write_file(_exc_path, render_result)

        logger.info('Generate exc.py.')

    def gen_log(self):
        _log_path = os.path.join(self.python_pack_dir, 'log.py')
        render_result = self.templates['log'].render()
        tools.write_file(_log_path, render_result)

        logger.info('Generate log.py.')

    def gen_consts(self):
        _consts_path = os.path.join(self.python_pack_dir, 'consts.py')
        render_result = self.templates['consts'].render()
        tools.write_file(_consts_path, render_result)

        logger.info('Generate consts.py.')
