#!/bin/bash

set -e

TIMEOUT=3

HEALTH_URL="http://localhost/health"

if timeout "$TIMEOUT" curl -f -s "$HEALTH_URL" > /dev/null 2>&1; then
	echo "✅ Nginx is healthy and responding at $HEALTH_URL"
	exit 0
else
	echo "❌ Nginx health check failed! Not responding at $HEALTH_URL within ${TIMEOUT}s"
	exit 1
fi
