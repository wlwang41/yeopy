# -*- coding: utf-8 -*-


class CODES(object):

    SUCCESS = (0, u'')
    FAILURE = (1, u'')

    HTTP_FAILURE = (10001, u'')
    RESOURCE_EXIST = (50000, u'')
    RESOURCE_NOT_FOUND = (10002, u'')
    SAVE_CANNOT_PASS_FIELDS = (10003, u'')


class {{pexc}}(Exception):
    default = CODES.FAILURE

    def __init__(self, code_tuple=None, msg=None):
        if not code_tuple:
            code_tuple = self.__class__.default
        self.code = code_tuple[0]

        if msg:
            if not isinstance(msg, unicode):
                msg = msg.decode('utf-8')
            self.msg = u'%s: %s' % (code_tuple[1], msg)
        else:
            self.msg = code_tuple[1]

    def __unicode__(self):
        return u'%s: %s' % (self.code, self.msg)

    def __str__(self):
        return self.msg.encode('utf8')
