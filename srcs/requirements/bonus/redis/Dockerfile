ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

# Install Redis
RUN apk add --no-cache redis

# Copy the Redis configuration file
COPY tools/redis.conf /etc/redis.conf

RUN chown redis:redis /etc/redis.conf

# Expose the Redis port internally
EXPOSE 6379

USER redis

CMD ["redis-server", "/etc/redis.conf"]
