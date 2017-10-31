{ cfg
}:

''
################################################################################
# RhodeCode VCSServer with HTTP Backend - configuration                        #
################################################################################


[server:main]
## COMMON ##
host = ${cfg.hostname}
port = ${toString cfg.port}


##########################
## GUNICORN WSGI SERVER ##
##########################
## run with gunicorn --log-config vcsserver.ini --paste vcsserver.ini
use = egg:gunicorn#main
## Sets the number of process workers. Recommended
## value is (2 * NUMBER_OF_CPUS + 1), eg 2CPU = 5 workers
workers = 2
## process name
proc_name = rhodecode_vcsserver
## type of worker class, currently `sync` is the only option allowed.
worker_class = sync
## The maximum number of simultaneous clients. Valid only for Gevent
#worker_connections = 10
## max number of requests that worker will handle before being gracefully
## restarted, could prevent memory leaks
max_requests = 1000
max_requests_jitter = 30
## amount of time a worker can spend with handling a request before it
## gets killed and restarted. Set to 6hrs
timeout = 21600


[app:main]
use = egg:rhodecode-vcsserver

pyramid.default_locale_name = en
pyramid.includes =

## default locale used by VCS systems
locale = en_US.UTF-8

# cache regions, please don't change
beaker.cache.regions = repo_object
beaker.cache.repo_object.type = memorylru
beaker.cache.repo_object.max_items = 100
# cache auto-expires after N seconds
beaker.cache.repo_object.expire = 300
beaker.cache.repo_object.enabled = true


################################
### LOGGING CONFIGURATION   ####
################################
[loggers]
keys = root, vcsserver, beaker

[handlers]
keys = console

[formatters]
keys = generic

#############
## LOGGERS ##
#############
[logger_root]
level = NOTSET
handlers = console

[logger_vcsserver]
level = DEBUG
handlers =
qualname = vcsserver
propagate = 1

[logger_beaker]
level = DEBUG
handlers =
qualname = beaker
propagate = 1


##############
## HANDLERS ##
##############

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = DEBUG
formatter = generic

################
## FORMATTERS ##
################

[formatter_generic]
format = %(asctime)s.%(msecs)03d %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %Y-%m-%d %H:%M:%S
''
