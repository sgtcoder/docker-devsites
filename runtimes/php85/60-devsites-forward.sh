#!/bin/sh
# Projects' .env files use 127.0.0.1 for MySQL and Redis (right on the Mac).
# Forward those ports to the swarm services so the same .env works in here.
nohup socat TCP-LISTEN:3306,bind=127.0.0.1,fork,reuseaddr TCP:mariadb:3306 >/dev/null 2>&1 &
nohup socat TCP-LISTEN:6379,bind=127.0.0.1,fork,reuseaddr TCP:keydb:6379 >/dev/null 2>&1 &
