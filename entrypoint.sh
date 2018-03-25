#!/bin/bash -x
cd /usr/local/etc
pg_md5 --md5auth --username=${USER:-postgres} ${PASS:-password} 
envsubst < pgpool.conf.mod > pgpool.conf
pgpool -n -d
