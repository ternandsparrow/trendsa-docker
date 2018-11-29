#!/bin/sh
cd $BACKUP_DIR
now=`date`
thefile=`find . -type f` # only expect one file
if [ -z "$thefile" ]; then
  echo 'Error: could not find file to backup'
  exit
fi
echo "[$now] performing S3 sync of $thefile"
set -e
aws s3 cp $thefile s3://$S3_BUCKET
echo "S3 sync done"

