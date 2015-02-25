#!/bin/bash
docker build -t spali/fusionpbx . ;docker stop fusionpbx;docker rm fusionpbx;
docker run -d --name fusionpbx -p 443:443 -p 5060:5060/tcp -p 5060:5060/udp -p 16384:16384/udp -p 16385:16385/udp -p 16386:16386/udp -p 16387:16387/udp -p 16388:16388/udp -p 16389:16389/udp -p 16390:16390/udp -p 16391:16391/udp -p 16392:16392/udp -p 16393:16393/udp -v /root/data/freeswitch:/etc/freeswitch -e VIRTUAL_HOST=c.dihei.ch -e VIRTUAL_PORT=80 spali/fusionpbx
