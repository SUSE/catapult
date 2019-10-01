FROM alpine:3.6

ARG EKCP_HOST
# copy crontabs for root user
COPY cronjobs /etc/crontabs/root
COPY sync.sh /usr/local/bin/sync.sh
RUN chmod +x /usr/local/bin/sync.sh
RUN apk update && apk add docker curl jq
RUN sed -i "s/sh/EKCP_HOST=$EKCP_HOST sh/" /etc/crontabs/root

# start crond with log level 8 in foreground, output to stderr
CMD ["crond", "-f", "-d", "8"]
