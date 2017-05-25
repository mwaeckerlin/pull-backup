#!/bin/bash

if test -z "$REMOTE" -a \( -z "${REMOTE_USER}" -o -z "${REMOTE_HOST}" -o -z "${REMOTE_PATH}" \); then
    echo "set REMOTE variable as user@host:/path/to/origin/";
    exit 1;
fi;
REMOTE=${REMOTE:-${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH// / ${REMOTE:USER}@${REMOTE_HOST}:}}
REMOTE_USER_HOST=${REMOTE%%:*}
REMOTE_USER=${REMOTE_USER:-${REMOTE_USER_HOST%@*}}
REMOTE_HOST=${REMOTE_HOST:-${REMOTE_USER_HOST#*@}}
if ! test -f ~/.ssh/id_rsa.pub; then
    echo | ssh-keygen -qb ${KEYSIZE} -N ""; echo;
    ssh-keyscan -H ${REMOTE_HOST} >> ~/.ssh/known_hosts;
fi;
echo "Please append the following key (without the dashed-lines) to:";
echo "host: ${REMOTE_HOST}";
echo "file: ~${REMOTE_USER}/.ssh/authorized_keys";
echo "-------------------------------------------------------------------------------------";
cat ~/.ssh/id_rsa.pub;
echo "-------------------------------------------------------------------------------------";
! test -e /root/log || rm /root/log;
ln -sf /proc/self/fd/1 /root/log;
COMMAND='rsync '"${RSYNC_OPTIONS}"' -e "ssh -p '"${PORT}"' -o stricthostkeychecking=no -o userknownhostsfile=/dev/null -o batchmode=yes -o passwordauthentication=no" '"${REMOTE}"' /backup/ 2>&1';
echo "$TIME root "'( echo "**** $(date) start backup of '${REMOTE}'"; '"${COMMAND}"' && echo "     $(date) success." || echo "     $(date) failed." ) >> /root/log' > /etc/crontab;
echo "waiting ${SLEEP} seconds before first backup, copy above key to ${REMOTE_USER_HOST}";
sleep ${SLEEP};
echo "Backup command is: ${COMMAND}";
echo "starting first backup";
while ! bash -c "${COMMAND}"; do echo "**** first backup failed, retry..."; done;
echo "++++ first backup done, entering cron mode";
cron -fL7
