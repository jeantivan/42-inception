# Stage 1
ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION} AS builder

RUN apk add --no-cache \
	nginx \
	ca-certificates \
	tzdata \
	openssl \
	curl \
	bash \
	&& update-ca-certificates
# && update-ca-certificates

RUN mkdir -p /var/log/nginx \
	/etc/nginx/conf.d \
	/etc/nginx/ssl \
	/usr/share/nginx/html

COPY tools/conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/conf/default.conf /etc/nginx/conf.d/default.conf

# Adjust permissions
RUN chown -R nginx:nginx /var/log/nginx && \
	chown -R nginx:nginx /etc/nginx && \
	chown -R nginx:nginx /usr/share/nginx/html && \
	chmod -R 755 /etc/nginx && \
	chmod -R 755 /usr/share/nginx/html

# Copy scripts
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY tools/healthcheck.sh /usr/local/bin/healthcheck.sh
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh

# Permission for entrypoint and healthcheck scripts
RUN chmod +x /usr/local/bin/entrypoint.sh && \
	chmod +x /usr/local/bin/healthcheck.sh && \
	chmod +x /usr/local/bin/generate-certs.sh

# Expose ports
EXPOSE 443

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
	CMD /usr/local/bin/healthcheck.sh

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["nginx", "-g", "daemon off;"]
