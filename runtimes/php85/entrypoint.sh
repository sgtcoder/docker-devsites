#!/bin/sh
# Runs each /etc/entrypoint.d script (the socat forwarders), then PHP-FPM or the given command.
for script in /etc/entrypoint.d/*.sh; do
    [ -r "$script" ] && . "$script"
done
exec "$@"
