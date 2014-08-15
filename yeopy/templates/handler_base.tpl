# -*- coding: utf-8 -*-

import tornado.web

from .. import exc
from ..tools import encode_json


class BaseHandler(tornado.web.RequestHandler):
    __return__ = 'json'
    __error_code__ = 400
    # __exception_handlers = {
    #     exc.APIRequestError: '_handle_api_error',
    # }

    def _handle_error(self, e):
        d = {
            'code': getattr(e, 'code', 1),
            'msg': str(e)
        }
        code = self.__error_code__
        if self.get_argument('__return_code', None):
            code = int(self.get_argument('__return_code'))
            # useless maybe
            if code != 200:
                code = 400
        self.write_data(d, code=code, no_wrap=True)

    def _handle_other_error(self, e):
        d = {
            'code': exc.CODES.FAILURE[0],
            'msg': exc.CODES.FAILURE[1]
        }
        self.write_data(d, code=400, no_wrap=True)

    EXCEPTION_HANDLERS = {
        (exc.{{pexc}}): '_handle_error',
        (Exception): '_handle_other_error'
    }

    def _handle_request_exception(self, e):
        handle_func = super(BaseHandler, self)._handle_request_exception
        if self.EXCEPTION_HANDLERS:
            for excs, func_name in self.EXCEPTION_HANDLERS.iteritems():
                if isinstance(e, excs):
                    handle_func = getattr(self, func_name)
                    break

        handle_func(e)
        if not self._finished:
            self.finish()

    def write_data(self, data, **kwargs):
        d = data if kwargs.get('no_wrap') else {'data': data}

        if self.__return__ == 'json_as_plain_text':
            if kwargs.get('code'):
                self.set_status(kwargs.get('code'))

            json_str = encode_json(d)
            self.set_header("Content-Type", "text/plain; charset=UTF-8")
            self.write(json_str)

        else:
            self.write_json(d,
                            code=kwargs.get('code'),
                            headers=kwargs.get('headers'))

    def write_jsonp(self, data):
        callback = self.get_argument('callback', None)
        if not callback:
            self.write_data(data, no_wrap=True)
            return
        json_str = encode_json(data)
        self.set_header("Content-Type", "application/javascript; charset=UTF-8")
        self.write('%s(%s);' % (callback, json_str))

    def write_json(self, data, code=None, headers=None):
        assert data is not None, 'None cound not be written in write_json'
        chunk = encode_json(data)

        self.set_header("Content-Type", "application/json; charset=UTF-8")
        if code:
            self.set_status(code)
        if headers:
            for k, v in headers.iteritems():
                self.set_header(k, v)

        self.write(chunk)
