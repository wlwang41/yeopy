# -*- coding: utf-8 -*-

import servers


def conf_supervisor(**kw):
    kw_spv = {
        'logfile': '%(here)s/var/{{pname}}_spv.log',
        'loglevel': 'info',
        'identifier': '{{pname}}_spv',
        'user': 'nobody',
        'pidfile': '%(here)s/var/{{pname}}_spv.pid',
        'childlogdir': '%(here)s/var/',
        'port': '8100',
        'username': 'user',
        'password': '123456',
        'program': '{{pname}}',
        'directory': '/opt/www.d/{{pname}}/',
        'environment': 'PYTHONPATH=.:sys.path',
        'command': '/opt/python/bin/python -m {{pname}}.app --port=80%(process_num)02d --debug=False',
        'numprocs': '2',
        'process_name': '{{pname}}_p80%(process_num)02d',
        'stdout_logfile': '%(here)s/var/{{pname}}.log',
        'stderr_logfile': '%(here)s/var/{{pname}}.err',
    }
    kw_spv.update(kw)
    tpl = """
[supervisord]
logfile = {logfile}
logfile_maxbytes = 50MB
logfile_backups=3
loglevel = {loglevel}
identifier = {identifier}
user = {user}
pidfile = {pidfile}
nocleanup = true
childlogdir = {childlogdir}

[inet_http_server]
port = {port}
username = {username}
password = {password}

[program:{program}]
directory={directory}
environment = {environment}
command = {command}
process_name = {process_name}
numprocs = {numprocs}
redirect_stderr = true
stdout_logfile = {stdout_logfile}
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups=3
stderr_logfile = {stderr_logfile}
stderr_logfile_maxbytes = 50MB
stderr_logfile_backups=3
    """
    return tpl.format(**kw_spv)


kw_loconf = {
    'develop': {
        'mongo_host': '',
        'mongo_db': '',
        'rds_host': '',
    },
    'test': {
        'mongo_host': '',
        'mongo_db': '',
        'rds_host': '',
    },
    'product': {
        'mongo_host': '',
        'mongo_port': 27017,
        'mongo_db': '',
        'mongo_user': '',
        'mongo_pwd': '',
        'rds_host': '127.0.0.1',
        'rds_port': 7379,
        'flag_debug': False,
        #'http_client': 'curl',
        'logging': 'INFO',
    },
}


def local_config(**kw):
    kw_config = {
        'mongo_host': '127.0.0.1',
        'mongo_port': 27017,
        'mongo_db': '',
        'mongo_user': '',
        'mongo_pwd': '',
        'rds_host': '127.0.0.1',
        'rds_port': 6379,
        'rds_db': 0,
        'http_client': 'simple',
        'log_path': '/tmp/{{pname}}/',
        'logging': 'DEBUG',
        'flag_debug': True,
    }
    kw_config.update(kw)
    tpl = """
HTTP_CLIENT = '{http_client}'
MONGODB_HOST = '{mongo_host}'
MONGODB_PORT = '{mongo_port}'
MONGODB_DB = '{mongo_db}'
MONGODB_USER = '{mongo_user}'
MONGODB_PWD = '{mongo_pwd}'
REDIS_HOST = '{rds_host}'
REDIS_PORT = {rds_port}
REDIS_DB = {rds_db}
LOG_PATH = '{log_path}'
LOGGING = '{logging}'
DEBUG = {flag_debug}
    """
    return tpl.format(**kw_config)


def port_base(mark):
    if mark.lower() == 'a':
        return 240
    elif mark.lower() == 'b':
        return 250
    elif mark.lower() == 'c':
        return 260
    elif mark.lower() == 'd':
        return 270
    elif mark.lower() == 'e':
        return 280
    return 290


def nginx_conf(backend='backend', optpath="/opt", mark="", domain="pfile.kuaizhan.com", files_path="/opt/pfiles/plugins"):
    portbase = port_base(mark)

    hosts = servers.roles.get(backend, [])
    lst = []
    for hs in hosts:
        h = hs.split('@', 1)[-1].split(':', 1)[0]
        cn = servers.hosts.get(hs, {}).get('cpu')
        if not cn or not h:
            continue
        #lst.extend(["server %s:%s%02d max_fails=3 fail_timeout=30s;" % (h,portbase,i) for i in range(cn)])
        lst.extend(["server %s:%s%02d;" % (h, portbase, i) for i in range(cn)])

    tpl = """
""" + (lst and """upstream {{pname}}.backend_""" + mark + """ {
    """ + "\n    ".join(lst) + """
}""" or "") + """
server {
    listen  80;
    server_name """ + domain + """;
""" + (lst and """
    location / {
        proxy_pass_header Server;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Scheme $scheme;
        client_max_body_size    10m;
        proxy_connect_timeout   100ms;
        #proxy_send_timeout      1s;
        #proxy_read_timeout      1s;
        proxy_temp_file_write_size 1024m;
        proxy_buffer_size         32k;
        proxy_buffers             4 32k;
        proxy_busy_buffers_size 64k;
        proxy_ignore_client_abort on;
        #proxy_next_upstream error timeout invalid_header http_502 http_503 http_504;
        proxy_pass http://{{pname}}.backend_""" + mark + """;
    }
    location /files/ {
        alias """ + files_path + """;
        autoindex off;
        access_log off;
        expires max;
    }
}
""") + """
    """
    return tpl


kw_nutcracker = {
    'develop': {
        'role': 'develop',
        'ip': '',
        'port': '7379',
        'servers': []
    },
    'test': {
        'role': 'test',
        'ip': '127.0.0.1',
        'port': '7379',
        'servers': []
    },
    'product': {
        'role': 'product',
        'ip': '127.0.0.1',
        'port': '7379',
        'servers': []
    },
}


def nutcracker_conf(**kw):
    tpl = """
{role}:
  listen: {ip}:{port}
  hash: fnv1a_64
  distribution: ketama
  redis: true
  auto_eject_hosts: true
  server_retry_timeout: 1000
  server_failure_limit: 3
  servers:
{servers}
    """
    got_kw = dict(kw)
    srv_str = "\n".join("   - " + s for s in got_kw.pop('servers'))
    return tpl.format(servers=srv_str, **got_kw)
