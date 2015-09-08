FROM ubuntu
MAINTAINER mwaeckerlin

ENV REMOTE ""
ENV TIME "0 3 * * *"
ENV SLEEP 60
ENV RSYNC_OPTIONS "-aq --delete-before"
VOLUME /backup
VOLUME /root

RUN apt-get install -y openssh-client cron rsync
WORKDIR /backup
CMD if test -z "$REMOTE"; then echo "set REMOTE variable as user@host:/path/to/origin/"; exit 1; fi; \
    REMOTE_USER_HOST=${REMOTE%%:*}; \
    REMOTE_PATH=${REMOTE#*:}; \
    REMOTE_USER=${REMOTE_USER_HOST%@*}; \
    REMOTE_HOST=${REMOTE_USER_HOST#*@}; \
    if ! test -f ~/.ssh/id_rsa.pub; then echo | ssh-keygen -qb 1024 -N ""; echo; fi; \
    if ! test -f ~/.ssh/known_hosts; then ssh-keyscan -H ${REMOTE_HOST} > ~/.ssh/known_hosts; fi; \
    echo "Please append the following key (without the dashed-lines) to:"; \
    echo "host: ${REMOTE_HOST}"; \
    echo "file: ~${REMOTE_USER}/.ssh/authorized_keys"; \
    echo "-------------------------------------------------------------------------------------"; \
    cat ~/.ssh/id_rsa.pub; \
    echo "-------------------------------------------------------------------------------------"; \
    touch /root/log; \
    COMMAND='( echo "**** $(date) start backup of '${REMOTE}'"; rsync '${RSYNC_OPTIONS}' -e "ssh -o stricthostkeychecking=no -o userknownhostsfile=/dev/null -o batchmode=yes -o passwordauthentication=no" '"${REMOTE}"' /backup/ 2>&1 && echo "     $(date) success." || echo "     $(date) failed." ) >> /root/log'; \
    echo "$TIME root ${COMMAND}" > /etc/crontab; \
    echo "waiting ${SLEEP} seconds before first backup, copy above key to ${REMOTE_USER_HOST}"; \
    sleep ${SLEEP}; \
    echo "starting first backup"; \
    bash -c "${COMMAND}"; \
    echo "first backup done, entering cron mode"; \
    cron -fL7
