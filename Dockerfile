FROM alpine:3.13.4

ENV USER_NAME=example@example.org
ENV USER_PASS=example

RUN apk add --update curl jq tzdata && rm -rf /var/cache/apk/*
RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime

WORKDIR /root
COPY ./src/exec.sh .

ENTRYPOINT ["/bin/sh"]
CMD ["/root/exec.sh"]