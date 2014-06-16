# -*- coding: utf-8 -*-

import tornado.web
import tornado.gen
import tornado.ioloop
import tornado.options
import tornado.httpclient

from .tools import route

tornado.options.define("port", default=8008, help="run on the given port", type=int)
tornado.options.define("debug", type=bool, default=True, help="run in debug mode with autoreload")

tornado.httpclient.AsyncHTTPClient.configure("tornado.simple_httpclient.SimpleAsyncHTTPClient", max_clients=3)

tornado.options.parse_command_line()

application = tornado.web.Application(
    route.get_routes(),
    debug=tornado.options.options.debug)


def main():
    application.listen(tornado.options.options.port, "0.0.0.0", xheaders=True)
    tornado.ioloop.IOLoop.instance().start()


if __name__ == "__main__":
    main()
