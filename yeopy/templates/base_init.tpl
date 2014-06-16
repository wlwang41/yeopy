# -*- coding: utf-8 -*-

from mongokit import Connection, Document
from .. import consts
from ..exc import {{pexc}}
from ..exc import CODES

connection_uri = 'mongodb://%s:%s/%s' % (consts.MONGODB_HOST, consts.MONGODB_PORT, consts.MONGODB_DB)
if consts.MONGODB_USER:
    connection_uri = 'mongodb://%s:%s@%s:%s/%s' % (consts.MONGODB_USER,
                                                   consts.MONGODB_PWD,
                                                   consts.MONGODB_HOST,
                                                   consts.MONGODB_PORT,
                                                   consts.MONGODB_DB)

conn = Connection(connection_uri,
                  max_pool_size=consts.MONGO_MAX_POOL_SIZE,
                  connectTimeoutMS=consts.MONGO_CONNECT_TIMEOUT_MS,
                  socketTimeoutMS=consts.MONGO_SOCKET_TIMEOUT_MS,
                  waitQueueTimeoutMS=consts.MONGO_WAIT_QUEUE_TIMEOUT_MS,
                  waitQueueMultiple=consts.MONGO_WAIT_QUEUE_MULTIPLE)


class BaseDoc(Document):
    __database__ = consts.MONGODB_DB

    # use_dot_notation = True
    use_schemaless = True

    def find_one_without_none(self, *args, **kwargs):
        rv = self.collection.find_one(wrap=self._obj_class, *args, **kwargs)
        if not rv:
            raise {{pexc}}(CODES.RESOURCE_NOT_FOUND, msg=self.collection.name)
        return rv

    # def save(self, *args, **kwargs):
    #     str_keys = self.structure.keys()
    #     str_keys.append('_id')
    #     _keys = self.keys()
    #     if set(_keys) == set(self.structure.keys()) \
    #        or set(_keys) == set(str_keys):
    #         super(BaseDoc, self).save(*args, **kwargs)
    #     else:
    #         raise {{pexc}}(CODES.SAVE_CANNOT_PASS_FIELDS)


# Import your models class here!!!
# such as: from .reputation import Medal, User, Rule, Field, Strategy
