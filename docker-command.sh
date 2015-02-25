#!/bin/bash
set -e

/usr/bin/freeswitch -nf -u freeswitch -g freeswitch &
/usr/sbin/php5-fpm --nodaemonize &
/usr/sbin/nginx &
wait

