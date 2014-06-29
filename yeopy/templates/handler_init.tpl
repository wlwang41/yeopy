#!/usr/bin/env python
# -*- coding: utf-8 -*-


class route(object):
    """
    Example
    -------

    @route('/some/path')
    class SomeRequestHandler(RequestHandler):
        pass

    @route('/some/path', name='other')
    class SomeOtherRequestHandler(RequestHandler):
        pass

    my_routes = route.get_routes()
    """
    _routes = []

    def __init__(self, uri):
        self._uri = uri

    def __call__(self, _handler):
        """gets called when we class decorate"""
        self.__class__._routes.append((self._uri, _handler))
        return _handler

    @classmethod
    def get_routes(cls):
        return cls._routes


from . import (
    *,  # TODO: CHANGE TO YOUR HANDLERS
)
