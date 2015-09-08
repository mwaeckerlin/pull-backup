# Docker Image that Pulls Backups from a Remote Host

Configuration is through two environment variables:
- `REMOTE` declares the remote site that has to be backed up in the form `user@host:/path/to/origin/`
- `TIME` backup time in `cron` format, defaults to `0 3 * * *` (nightly at three o'clock)
- `SLEEP` time in seconds before the initial backup starts (60s)
- `RSYNC_OPTIONS` options passed to rsync, defaults to `-aq` see `man rsync` for details

The volumes are:
- `/backup` the backup target
- `/root` contains the file `log` with backup results and the directory `.ssh` with ssh keys

Please note, that your local network's DNS might not be available in the docker container, so use IP addresse in that case.

When you start the docker container, it outputs the public ssh key to the docker logs. You need to append this to the remote user's `~/.ssh/authorized_keys` file.

The key line looks somehow like this:

        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCvwSsm0Qw8PSupDh+/pSp0lo339UuHizLC/+XPNv7IvI2yc732XPO5wFQKMUz1p+dCm5XHXcGJArn5gm+gEKQD+97LM53Y2aEsL2J39oKLxoc5V4me82vgb0p0j4+Qq7iMjaKa8z5kOUvG4zxBM1It/wdvxM35zq65J48Q3L4vdw== root@850fe0680855

When you start the container, it starts with an initial backup after one minute. Use that time to copy the public key to the user's `~/.ssh/authorized_keys` in the origin's host. If you need more time, set the environment variable `SLEEP` (in seconds).