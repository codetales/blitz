#!/bin/bash
set -e
COMMAND=${1-run}
shift

[ -d "${UNISON_DATA}" ] || mkdir "${UNISON_DATA}"

if [ "$USERID" -ne 0 ]
then
  deluser ${USERNAME} --remove-home || true
  adduser -h /home/${USERNAME} -s /bin/bash -u $USERID -D ${USERNAME}
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} "${UNISON_DATA}" "${DEST_PATH}"
  [ -L /home/${USERNAME}/.unison ] || ln -s "${UNISON_DATA}" /home/${USERNAME}/.unison
  EXECUTOR="su-exec ${USERNAME}"
else
  [ -L /root/.unison ] || ln -sf "${UNISON_DATA}" /root/.unison
  EXECUTOR="exec"
fi

UNSION_COMMAND="${EXECUTOR} unison ${DEFAULT_OPTS} ${UNISON_OPTS}"

case "$COMMAND" in
  run)
    RUN="${UNSION_COMMAND} \"${SRC_PATH}\" \"${DEST_PATH}\""
    ;;

  watch)
    RUN="${UNSION_COMMAND} -repeat watch \"${SRC_PATH}\" \"${DEST_PATH}\""
    ;;

  reset)
    while true; do
      read -p "A reset will delete all data in ${UNISON_DATA} and ${DEST_PATH}. Do you want to proceed? " yn
      case $yn in
        [Yy]* ) rm -rfv "${UNISON_DATA}/*" "${DEST_PATH}/*"; exit;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
    done
    ;;

  *)
    exec $COMMAND "$@"
    ;;
esac

echo $RUN
eval $RUN
