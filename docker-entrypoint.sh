#!/bin/bash
set -e

###
# Setting up the environment
###
if [ "$SYNC_UID" -ne 0 ]
then
  export SYNC_USER_HOME=/home/${SYNC_USER}
  deluser ${SYNC_USER} --remove-home || true
  adduser -h ${SYNC_USER_HOME} -s /bin/bash -u $SYNC_UID -D ${SYNC_USER}
  chown -R ${SYNC_USER}:${SYNC_USER} ${SYNC_USER_HOME} "${UNISON_DATA}" "${CONTAINER_DATA_PATH}"
  [ -L /home/${SYNC_USER}/.unison ] || ln -s "${UNISON_DATA}" ${SYNC_USER_HOME}/.unison
  export SYNC_EXECUTOR="su-exec ${SYNC_USER}"
else
  [ -L /root/.unison ] || ln -sf "${UNISON_DATA}" /root/.unison
  export SYNC_USER_HOME=/root
  export SYNC_USER=root
  export SYNC_EXECUTOR="exec"
fi

###
# Starting ssync
###

UNSION_COMMAND="unison ${UNISON_DEFAULT_OPTS} ${UNISON_OPTS}"

COMMAND=${1-run}
shift

case "$COMMAND" in
  run)
    echo ${SYNC_EXECUTOR} ${UNSION_COMMAND} "${HOST_DATA_PATH}" "${CONTAINER_DATA_PATH}"
    eval ${SYNC_EXECUTOR} ${UNSION_COMMAND} "${HOST_DATA_PATH}" "${CONTAINER_DATA_PATH}"
    ;;

  watch)
    envsubst /etc/monitrc.template > /etc/monitrc
    # sed ... > monitrc
    export UNISON_START_COMMAND="${UNSION_COMMAND} -repeat watch \"${HOST_DATA_PATH}\" \"${CONTAINER_DATA_PATH}\""
    exec supervisord
    ;;

  reset)
    while true; do
      read -p "A reset will delete all data in ${UNISON_DATA} and ${CONTAINER_DATA_PATH}. Do you want to proceed? " yn
      case $yn in
        [Yy]* ) rm -rf "${UNISON_DATA}/"* "${CONTAINER_DATA_PATH}"/*; exit;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
    ;;

  *)
    exec $COMMAND "$@"
    ;;
esac
