ARG ALPINE_VERSION=${ALPINE_VERSION:-3.22}
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
	vsftpd \
	shadow netcat-openbsd

RUN mkdir -p /var/run/vsftpd/empty \
	/var/log/vsftpd \
	/var/ftp \
	/var/www/html

RUN chmod 555 /var/run/vsftpd/empty

COPY tools/vsftpd.conf /etc/vsftpd/vsftpd.conf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 30000-30009

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["vsftpd", "/etc/vsftpd/vsftpd.conf"]
