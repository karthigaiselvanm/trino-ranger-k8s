#!/bin/sh

# Wait for MySQL becomes available
sleep 30

cd $RANGER_HOME
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 ./setup.sh
ranger-admin start

# Keep the container running
tail -f /dev/null
