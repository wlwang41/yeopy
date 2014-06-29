#!/usr/bin/env python
# -*- coding: utf-8 -*-

hosts = {
    'root@127.0.0.1': {'role': ['backend', 'nginx'], 'cpu': 4, 'mem': 8, 'hd': 100, 'env': 'product'},

    'root@127.0.0.1': {'role': ['test'], 'cpu': 2, 'mem': 8, 'hd': 80, 'env': 'test'}
}


roles = {}
for h, c in hosts.iteritems():
    for role in c.get('role', []):
        hl = roles.setdefault(role, [])
        hl.append(h)
