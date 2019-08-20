FROM alpine:3.9

RUN apk add --no-cache \
        bash \
        gettext \
        monit \
        su-exec \
        supervisor

ARG UNISON_VERSION=2.51.2
ENV UNISON_VERSION=$UNISON_VERSION
RUN apk add --no-cache build-base curl ocaml \
      && curl -L https://github.com/bcpierce00/unison/archive/v$UNISON_VERSION.tar.gz | tar zxv -C /tmp \
      && cd /tmp/unison-${UNISON_VERSION} \
      && sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' src/fsmonitor/linux/inotify_stubs.c \
      && make UISTYLE=text NATIVE=true STATIC=true \
      && apk del build-base curl ocaml \
      && cp src/unison src/unison-fsmonitor /usr/local/bin \
      && rm -rf /var/cache/apk/* \
      && rm -rf /tmp/unison-${UNISON_VERSION}


ARG UNISON_DATA=/unison_data
ARG HOST_DATA_PATH=/host
ARG CONTAINER_DATA_PATH=/container
ENV \
  UNISONLOCALHOSTNAME=syncer \
  UNISON_DATA=/unison_data \
  UNISON_DEFAULT_OPTS="-batch -auto" \
  UNISON_OPTS="" \
  CONTAINER_DATA_PATH=$CONTAINER_DATA_PATH \
  HOST_DATA_PATH=$HOST_DATA_PATH \
  SYNC_UID=0 \
  SYNC_USER=syncer \
  MONIT_CHECK_INTERVAL=1 \
  MONIT_ENABLED=true \
  MONIT_HIGH_CPU_THRESHOLD=60 \
  MONIT_HIGH_CPU_CYCLES=5

RUN mkdir -p \
      /docker-entrypoint.d \
      /etc/supervisor.conf.d \
      $UNISON_DATA \
      $CONTAINER_DATA_PATH \
      $HOST_DATA_PATH

COPY docker-entrypoint.sh /
COPY monitrc.template supervisord.conf /etc/

VOLUME $UNISON_DATA
VOLUME $CONTAINER_DATA_PATH

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["run"]
