# Stage 1
ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION} AS builder

# Metadata
LABEL maintainer="dev.jeantivan@gmail.com"
LABEL description="Nginx with TLS 1.3 from scratch on Alpine Linux"

# Build variables
ARG NGINX_VERSION=1.29.4
ARG PCRE_VERSION=10.44
ARG ZLIB_VERSION=1.3.1
ARG OPENSSL_VERSION=3.1.5

# Install compilation dependencies
RUN apk add --no-cache --virtual .build-deps \
	gcc \
	libc-dev \
	make \
	openssl-dev \
	pcre-dev \
	zlib-dev \
	linux-headers \
	curl \
	gnupg \
	libxslt-dev \
	gd-dev \
	geoip-dev \
	perl-dev

# Download source code
WORKDIR /tmp
RUN curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz && \
	curl -fSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc -o nginx.tar.gz.asc

# Extract Nginx
RUN tar -xzf nginx.tar.gz && \
	mv nginx-${NGINX_VERSION} nginx

# Download PCRE (regex)
RUN curl -fSL https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VERSION}/pcre2-${PCRE_VERSION}.tar.gz -o pcre.tar.gz && \
	tar -xzf pcre.tar.gz

# Download Zlib (compression)
RUN curl -fSL https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz -o zlib.tar.gz && \
	tar -xzf zlib.tar.gz

# Download OpenSSL (TLS 1.3)
RUN curl -fSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o openssl.tar.gz && \
	tar -xzf openssl.tar.gz

# Configure and compile Nginx with modules
WORKDIR /tmp/nginx

RUN ./configure \
	--prefix=/etc/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/var/run/nginx.pid \
	--lock-path=/var/run/nginx.lock \
	--http-client-body-temp-path=/var/cache/nginx/client_temp \
	--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
	--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
	--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
	--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
	--user=nginx \
	--group=nginx \
	--with-compat \
	--with-file-aio \
	--with-threads \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_flv_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_mp4_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-mail \
	--with-mail_ssl_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--with-pcre=/tmp/pcre2-${PCRE_VERSION} \
	--with-pcre-jit \
	--with-zlib=/tmp/zlib-${ZLIB_VERSION} \
	--with-openssl=/tmp/openssl-${OPENSSL_VERSION} \
	--with-openssl-opt=enable-tls1_3 \
	--with-cc-opt="-O3 -fPIE -fstack-protector-strong" \
	--with-ld-opt="-Wl,-z,relro -Wl,-z,now -pie"

# Compile and install
RUN make -j$(nproc) && make install

# Directories structure
RUN mkdir -p /var/cache/nginx/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp} && \
	mkdir -p /var/log/nginx && \
	mkdir -p /etc/nginx/conf.d && \
	mkdir -p /etc/nginx/sites-available && \
	mkdir -p /etc/nginx/sites-enabled && \
	mkdir -p /etc/nginx/ssl && \
	mkdir -p /usr/share/nginx/html && \
	mkdir -p /usr/lib/nginx/modules

# Stage 2
FROM alpine:${ALPINE_VERSION}

# Metadata
LABEL maintainer="dev.jeantivan@gmail.com"
LABEL description="Nginx with TLS 1.3 from scratch on Alpine Linux"

# Environment variables
ENV NGINX_VERSION=1.26.2 \
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
	TZ=UTC

RUN apk add --no-cache \
	ca-certificates \
	tzdata \
	pcre \
	zlib \
	openssl \
	bash \
	curl \
	&& update-ca-certificates

# Create user nginx (without shell, with home, without password)
RUN addgroup -g 101 -S nginx && \
	adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx


# Copy binnaries and configuration files from builder stage
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/lib/nginx /usr/lib/nginx
COPY --from=builder /var/cache/nginx /var/cache/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
COPY --from=builder /usr/share/nginx/html /usr/share/nginx/html

# Copiar archivos de configuración personalizados
COPY tools/conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/conf/default.conf /etc/nginx/conf.d/default.conf

# Copy scripts from tools
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY tools/generate-certs.sh /usr/local/bin/generate-certs.sh
COPY tools/healthcheck.sh /usr/local/bin/healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/generate-certs.sh /usr/local/bin/healthcheck.sh


# Set permissions
RUN chown -R nginx:nginx /var/cache/nginx && \
	chown -R nginx:nginx /var/log/nginx && \
	chown -R nginx:nginx /etc/nginx && \
	chown -R nginx:nginx /usr/share/nginx/html && \
	chmod -R 755 /etc/nginx && \
	chmod -R 755 /usr/share/nginx/html && \
	find /usr/share/nginx/html -type f -exec chmod 644 {} \;

# Adjust permissions
RUN chown -R nginx:nginx /var/cache/nginx && \
	chown -R nginx:nginx /var/log/nginx && \
	chown -R nginx:nginx /etc/nginx && \
	chown -R nginx:nginx /usr/share/nginx/html && \
	chmod -R 755 /etc/nginx && \
	chmod -R 755 /usr/share/nginx/html

# Expose ports
EXPOSE 443

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
	CMD /usr/local/bin/healthcheck.sh

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["nginx", "-g", "daemon off;"]
