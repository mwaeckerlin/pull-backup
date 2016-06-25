# Docker Image that Pulls Backups from a Remote Host

Configuration is through two environment variables:
- `REMOTE` declares the remote site that has to be backed up in the form `user@host:/path/to/origin/`
- `TIME` backup time in `cron` format, defaults to `0 3 * * *` (nightly at three o'clock)
- `SLEEP` time in seconds before the initial backup starts (60s)
- `RSYNC_OPTIONS` options passed to rsync, defaults to `-aq --delete-before` see `man rsync` for details
- `KEYSIZE` ssh rsa key size, defaults to 4096

The volumes are:
- `/backup` the backup target
- `/root` contains the file `log` with backup results and the directory `.ssh` with ssh keys

Please note, that your local network's DNS might not be available in the docker container, so use IP addresse in that case.

When you start the docker container, it outputs the public ssh key to the docker logs. You need to append this to the remote user's `~/.ssh/authorized_keys` file.

The key line looks somehow like this:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCvwSsm0Qw8PSupDh+/pSp0lo339UuHizLC/+XPNv7IvI2yc732XPO5wFQKMUz1p+dCm5XHXcGJArn5gm+gEKQD+97LM53Y2aEsL2J39oKLxoc5V4me82vgb0p0j4+Qq7iMjaKa8z5kOUvG4zxBM1It/wdvxM35zq65J48Q3L4vdw== root@850fe0680855

When you start the container, it starts with an initial backup after one minute. Use that time to copy the public key to the user's `~/.ssh/authorized_keys` in the origin's host. If you need more time, set the environment variable `SLEEP` (in seconds).

Example:

Backup the data below path `/var/something` on host `192.168.0.99` and access it with user account `myname`. It is more secure, if user `myname` has only read access to `/var/something` and cannot access other paths on `192.168.0.99`. The backup is copied to the host where `docker` runs, there it is stored in path `/var/something-copy`.

Start the backup process on the target computer:

    docker run -d --name pull-backup-something \
               -v /var/something-copy:/backup \
               -e SLEEP=30 \
               -e RSYNC_OPTIONS="-av --delete-before" \
               -e REMOTE=myname@192.168.0.99:/var/something/ \
               mwaeckerlin/pull-backup

Get the key

    docker logs -f pull-backup-something

Copy the key to path `~myname/.ssh/authorized_keys` on host `192.168.0.99` within the thirty seconds before the initial backup starts.

See what actually happens in the backup log:

    docker logs -f pull-backup-something

Afert a while (see logs), local path `/var/something-copy` contains a backup of `/var/something` on host `192.168.0.99`.

That's all. The synchronization is repeated each day a 3 o'clock (UTC) in the morning.

The same command can be started on several computers to have more than one backup if your data is importand.

# Backup from remote Docker

It can easily be used in conjunciton with mwaeckerlin/ssh, e.g. to backup the subversion volume:

First, on the backup target machine, start a pull-backup container, e.g.:

    docker run -d --name svn-backup-pull \
               -e REMOTE="root@pulsar:/svn" \
               -e PORT="200" \
               mwaeckerlin/pull-backup \
    && docker logs -f svn-backup-pull

When you see the key, copy it and enter it, when you start the ssh server on the backup source machine, e.g,:

    docker run -d --name svn-backup-provider \
               -p 200:22 --volumes-from svn-volume \
               -e SSHKEY="ssh-rsa AAAAADAQAB…bL4jsnRWr5p2Q== root@f76c20a0e0cf" \
               mwaeckerlin/ssh
