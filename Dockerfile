FROM alpine:3.13.4

ENV USER_NAME=example@example.org
ENV USER_PASS=example
ENV SUMMER_SCHEDULE=no

RUN apk add --update curl jq bash tzdata && rm -rf /var/cache/apk/*
RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime

WORKDIR /root
COPY ./src/exec.sh /bin/sesametime

RUN chmod +x /bin/sesametime

ENTRYPOINT ["/bin/bash"]
CMD ["sesametime"]