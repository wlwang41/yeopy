# -*- coding: utf-8 -*-


class CODES(object):

    SUCCESS = (0, u'成功=. =')
    FAILURE = (1, u'系统发生了未知的错误')

    HTTP_FAILURE = (10001, u'网络请求失败')
    RESOURCE_EXIST = (50000, u'更新或创建的资源已经存在')
    RESOURCE_NOT_FOUND = (10002, u'资源没有找到')
    SAVE_CANNOT_PASS_FIELDS = (10003, u'save操作的字段比数据库中字段少')
    ITEMS_LENGTH_ERROR = (10004, u'表单长度不在0到20之间')
    FORM_REMOVED = (10005, u'该表单已经被删除')


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
