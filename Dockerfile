FROM ubuntu
MAINTAINER mwaeckerlin

ENV REMOTE ""
ENV PORT "22"
ENV TIME "0 3 * * *"
ENV SLEEP 60
ENV RSYNC_OPTIONS "-axqe ssh --delete-before"
ENV KEYSIZE 4096

RUN qpt-get update
RUN apt-get install -y openssh-client cron rsync
WORKDIR /backup
ADD start.sh /start.sh
CMD /start.sh

VOLUME /backup
VOLUME /root
