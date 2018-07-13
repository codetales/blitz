FROM alpine:3.7

RUN apk add --no-cache bash unison su-exec

ENV UNISON_DATA=/unison_data
ENV UNISONLOCALHOSTNAME=syncer
ENV SRC_PATH=/src DEST_PATH=/dest
ENV USERID=0 USERNAME=syncer
ENV DEFAULT_OPTS -batch -auto
ENV UNISON_OPTS=""

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
