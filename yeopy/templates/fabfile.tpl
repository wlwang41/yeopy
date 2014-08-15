# -*- coding: utf-8 -*-

import datetime
import os
from fabric.api import (
    env, local, cd, run,
    put, settings
)
# from fabric.contrib.console import confirm
from fabric.contrib.files import exists
import deploy.confs as confs
import deploy.servers as servers


git = env.get('git', 'git')
env.roledefs = servers.roles


def hello(name):
    print "Hello %s!" % name


def uname():
    run('uname -a')


def execute(cmd):
    run(cmd)


def upload(path, remote_path="~"):
    final_path = remote_path
    if not os.path.basename(remote_path):
        final_path = os.path.join(final_path, os.path.basename(path))
    put(path, final_path)


def pull(branch=None):
    if branch:
        local('%s checkout %s' % (git, branch))
    local('%s pull' % git)


def pack(branch, prefix="./", output="", remotes=False):
    """将git上的文件打包
    """
    #if not (remotes or branch.startswith('remotes/')):
    #    pull(git, branch)
    output = output or "{{pname}}_%s.tgz" % branch
    if remotes and not branch.startswith('remotes/'):
        branch = os.path.join('remotes/origin/', branch)
    prefix = prefix.endswith('/') and prefix or prefix + '/'
    local('%s archive --format=tgz --prefix=%s -o %s %s {{pname}} scripts' % (git, prefix, output, branch))


def clean():
    """NOTE: 清tmp目录，不应该叫clean啊
    """
    if os.path.exists('tmp'):
        local('rm -rf tmp')


def build_path(path, varchown='nobody', varchmod='774'):
    """服务器上创建path目录，并且在path下创建var目录，设置权限
    """
    with settings(warn_only=True):
        run('mkdir %s' % path)
        varpath = os.path.join(path, 'var')
        run('mkdir %s' % varpath)
    with cd(path):
        run('chown -R %s %s' % (varchown, varpath))
        run('chmod -R %s %s' % (varchmod, varpath))


def backendctl(opt, mark=""):
    """提供一些服务器操作命令

    start | restart | stop
    """
    hostconf = servers.hosts.get(env.host_string, {})
    opt_path = hostconf.get('optpath', '/opt')
    path = os.path.join(opt_path, 'www.d/{{pname}}') + (mark and '_' + mark or '')
    pidfile = os.path.join(path, 'var/{{pname}}_spv.pid')
    with cd(path):
        if opt == 'start':
            if exists(pidfile):
                print "Seems like already running."
                return
            # NOTE: supervisor的路径是写死的
            return run(os.path.join(opt_path, 'python/bin/supervisord') + ' -c supervisor.conf')
        elif opt == 'restart':
            if exists(pidfile):
                run('kill -HUP `cat %s`' % pidfile)
            else:
                run(os.path.join(opt_path, 'python/bin/supervisord') + ' -c supervisor.conf')
        elif opt == 'stop':
            if exists(pidfile):
                run('kill -TERM `cat %s`' % pidfile)
                #return run('rm %s' % pidfile)
            print "Seems like already stopped."


def deploy(branch, mark="", rebuild=True):
    """部署命令

    like: fab -R backend deploy:master,mark=b
    """
    # 确保本地有tmp目录,tmp用于存放git上面的文件
    clean()
    local('mkdir tmp')

    hostconf = servers.hosts.get(env.host_string, {})
    opt_path = hostconf.get('optpath', '/opt')

    path = os.path.join(opt_path, 'www.d/{{pname}}') + (mark and '_' + mark or '')
    if not exists(path):
        # 创建目录改变权限，并且创建var目录放配置信息
        build_path(path)

    if rebuild:
        backendctl('stop', mark)
        run('rm -rf %s' % path)
        build_path(path)

    # 将git上面的文件打包到本地的tmp目录下
    tgz = 'tmp/{{pname}}_%s.tgz' % branch
    pack(branch, output=tgz, remotes=True)

    # 上传文件到服务器
    remote_tgz = '{{pname}}_%s_%s.tgz' % (branch, datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
    put(tgz, os.path.join(path, remote_tgz))

    # 解压服务器上的代码文件
    with cd(path):
        run('rm -rf {{pname}}')
        run('tar zxf %s' % remote_tgz)

    # 写supervisor的配置
    # 服务器上supervisor的配置和项目代码同级
    # NOTE: var里面放的是进程号
    if not exists(os.path.join(path, 'supervisor.conf')):
        rebuild = True
    if rebuild:
        backendctl('stop', mark)

        # 生成supervisor.conf
        with open('tmp/supervisor.conf', 'w') as fh:
            # 得到不同版本的端口号
            portbase = confs.port_base(mark)
            kw = {
                'port': portbase * 100 + 100,
                'program': '{{pname}}' + (mark and '_' + mark or ''),
                'directory': path,
                # supervisor运行的项目app的命令
                # 我的写法起tornaod的时候默认是debug模式，线上就要关掉
                'command': os.path.join(opt_path, 'python/bin/python') + ' -m {{pname}}.app --port=' + str(portbase) + '%(process_num)02d --debug=False',
                # 起的进程数和cpu数一致
                'numprocs': hostconf.get('cpu', 1),
                'process_name': '{{pname}}_p' + str(portbase) + '%(process_num)02d',
            }
            fh.write(confs.conf_supervisor(**kw))

        # 生成localconfig文件
        with open('tmp/local_config.py', 'w') as fh:
            kw = dict(confs.kw_loconf.get(hostconf.get('env', 'develop'), {}))
            print repr(kw)
            kw.update({
                'log_path': os.path.join(path, 'var/'),
            })
            fh.write(confs.local_config(**kw))

        # 上传supervisor.conf 和 local_config.py
        put('tmp/local_config.py', os.path.join(path, 'local_config.py'))
        put('tmp/supervisor.conf', os.path.join(path, 'supervisor.conf'))

    backendctl('restart', mark)


# TODO(crow): 这里domain的默认值怎么给好呢
def nginx_conf(backend="inner", domain=""):
    """生成nginx的配置

    前面deploy，配置好的supervisor可以其几个tornado的进程
    配上nginx之后做个负载均衡
    由于端口号是由于不同版本配置是不同的，所以upstream的时候只能通过这个生成
    """
    clean()
    local('mkdir tmp')

    hostconf = servers.hosts.get(env.host_string, {})
    optpath = hostconf.get('optpath', '/opt')

    # 所有的不同版本的nginx配置都会在这里存一份
    conf_store = os.path.join(optpath, 'nginx/conf/conf.store.d')

    # 要确保在服务器上有conf.store.d的目录，不然直接return了
    if not exists(conf_store):
        print "warning: %s:%s doesn't exist!" % (env.hosts_string, conf_store)
        return

    for mark in ['a', 'b', 'c', 'd', 'e', '']:
        filename = '{{pname}}' + (mark and '_' + mark or '') + '.conf'
        confile = 'tmp/' + filename
        with open(confile, 'w') as fh:
            fh.write(confs.nginx_conf(backend, optpath, mark, domain))

        put(confile, os.path.join(conf_store, filename))


def switch(mark):
    hostconf = servers.hosts.get(env.host_string, {})
    optpath = hostconf.get('optpath', '/opt')

    # nginx 命令位置
    nginx_bin = os.path.join(optpath, 'nginx/sbin/nginx')

    conf_d = os.path.join(optpath, 'nginx/conf/conf.d')

    conf_store = os.path.join(optpath, 'nginx/conf/conf.store.d')

    filename = '{{pname}}' + (mark and '_' + mark or '') + '.conf'
    confile = os.path.join(conf_store, filename)

    finalname = '{{pname}}.conf'
    conlink = os.path.join(conf_d, finalname)

    # 集中判断上面的路径都要存在
    for fn in [nginx_bin, conf_store, conf_d, confile]:
        if not exists(fn):
            print "warning: %s:%s doesn't exist!" % (env.hosts_string, fn)
            return

    # 干掉现有的nginx配置
    if exists(conlink):
        run('rm -f %s' % conlink)

    # 设置一个软链接，将不同版本的nginx配置换到有效的上面
    with cd(conf_d):
        run('ln -s ../conf.store.d/%s %s' % (filename, finalname))

    # 测试一下配置是否正确
    run('%s -t' % nginx_bin)

    # 启动nginx
    if exists(os.path.join(optpath, 'nginx/logs/nginx.pid')):
        run('%s -s reload' % nginx_bin)
    else:
        run('%s' % nginx_bin)


def current():
    hostconf = servers.hosts.get(env.host_string, {})
    optpath = hostconf.get('optpath', '/opt')

    conf_d = os.path.join(optpath, 'nginx/conf/conf.d')
    finalname = '{{pname}}.conf'
    conlink = os.path.join(conf_d, finalname)
    if exists(conlink):
        run('ls -l %s' % conlink)
    else:
        run('echo "no current!"')
