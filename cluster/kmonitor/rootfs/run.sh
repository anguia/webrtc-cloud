#!/bin/sh
DAEMON=monitor-client.sh
EXEC=$(which $DAEMON)
ARGS="start-foreground"

info "Starting ${DAEMON}..."
exec ${EXEC} ${ARGS}
