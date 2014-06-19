#-*- coding: utf-8 -*-

import datetime
import base64
import bson
import json
import os
import random
import string
import urllib
import time
import uuid
import traceback
import tornado.web
from bs4 import BeautifulSoup, Comment


def enum(*sequential, **named):
    enums = dict(zip(sequential, range(len(sequential))), **named)
    return type('enum', (), enums)


def str2unicode(ustr, decoding='utf-8'):
    if isinstance(ustr, unicode):
        return ustr
    return unicode(ustr, decoding, 'replace')


def unicode2str(string, encoding='utf-8'):
    if isinstance(string, unicode):
        return string.encode(encoding, 'replace')
    return str(string)


def _handle_object_for_json(obj):
    if isinstance(obj, bson.ObjectId):
        return oid2str(obj)
    if isinstance(obj, datetime.datetime):
        return datetime2timestamp(obj) * 1000
    if hasattr(obj, 'to_dict'):
        return obj.to_dict()


def decode_json(json_str):
    return json.loads(json_str)


def encode_json(data):
    return json.dumps(data, default=_handle_object_for_json)


def print_exc():
    print '-' * 72
    traceback.print_exc()
    print '-' * 72


letters = string.ascii_letters + string.digits
randstr = lambda length, letters=letters:\
    ''.join(random.choice(letters) for x in xrange(length))


b64urandom = lambda length=15: base64.urlsafe_b64encode(os.urandom(length))


def uuid2str(data, b64=True):
    if isinstance(data, uuid.UUID):
        if b64:
            return base64.b64encode(data.bytes, "-_")
        return data.hex
    return data


def str2uuid(data, b64=True):
    if b64:
        try:
            data = base64.b64decode(data, '-_').encode('hex')
        except:
            pass
    return uuid.UUID(data)


def urlquote(v, encoding='utf-8'):
    return urllib.quote(unicode2str(v, encoding), safe='')


def oid2str(data, b64=True):
    if isinstance(data, bson.ObjectId):
        if b64:
            return base64.b64encode(data.binary, '-_')
        return str(data)
    return data


def str2oid(data, b64=True):
    if b64:
        try:
            data = base64.b64decode(data, "-_")
        except:
            pass
    return bson.ObjectId(data)


def get_time_as_long():
    return long(time.time() * 1000)


def get_time_as_datetime(utc=True):
    return datetime.datetime.utcnow() if utc else datetime.datetime.now()


def datetime2timestamp(dtime):
    if isinstance(dtime, datetime.datetime):
        return long(time.mktime(dtime.timetuple()))
    return dtime


def timestamp2datetime(timestamp):
    if isinstance(timestamp, datetime.datetime):
        return timestamp
    return datetime.datetime.fromtimestamp(timestamp)


def wash_html(string, return_soup=True):
    if not string:
        string = ''
    soup = BeautifulSoup(string)
    comments = soup.findAll(text=lambda text: isinstance(text, Comment))
    [comment.extract() for comment in comments]
    for tag in soup.findAll():
        if tag.name in ['script', 'style', 'meta', 'link']:
            tag.decompose()
        elif tag.name not in ['p', 'a', 'br', 'img']:
            tag.unwrap()
        elif tag.name == 'a':
            href = tag.attrs.get('href')
            tag.attrs = href and {'href': href} or {}
        elif tag.name == 'img':
            attrs = {
                "src": tag.attrs.get('src'),
                "data-src": tag.attrs.get('data-src'),
                "data-video": tag.attrs.get("data-video"),
                "data-link": tag.attrs.get("data-link"),
                "data-site": tag.attrs.get("data-site"),
            }
            tag.attrs = {k: v for k, v in attrs.iteritems() if v}
        else:
            tag.attrs = {}
    return soup if return_soup else soup.prettify()


def trim_html(string, is_gbk=False):
    soup = wash_html(string)
    return "".join(txt.strip() for txt in soup.findAll(text=True))


def gen_vcode(length=4):
    _chars = 'ABCDEFJHJKLMNPQRSTUVWXYcefhkmnrstuvwxy3456789'
    vcode = random.sample(_chars, length)
    return vcode


class route(object):
    """
    Everytime @route('...') is called, we instantiate a new route object which
    saves off the passed in URI.  Then, since it's a decorator, the function is
    passed to the route.__call__ method as an argument.  We save a reference to
    that handler with our uri in our class level routes list then return that
    class to be instantiated as normal.

    Later, we can call the classmethod route.get_routes to return that list of
    tuples which can be handed directly to the tornado.web.Application
    instantiation.

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
        self._routes.append((self._uri, _handler))
        return _handler

    @classmethod
    def get_routes(cls):
        return cls._routes


def route_redirect(from_, to):
    route._routes.append((from_, tornado.web.RedirectHandler, dict(url=to)))
