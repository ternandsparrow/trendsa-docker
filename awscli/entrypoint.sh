#!/bin/sh
set -e
: ${BACKUP_DIR:?}
: ${S3_BUCKET:?}
: ${CRON_SCHEDULE:?}
# doing the "tail the log files" becuase we can't redirect to /proc/1/fd/{1,2} for some reason
out=/tmp/out.log
err=/tmp/err.log
touch $out $err
tail -f $out $err &
redirectToDockerLogs=">> $out 2>> $err"
echo "$CRON_SCHEDULE /run.sh $redirectToDockerLogs" > /var/spool/cron/crontabs/root
echo "starting crond..."
crond -l 2 -f

