#!/bin/sh
set -e
uniqueFragment=`date +%Y%m%d_%H%M`
cd $BACKUP_DIR
rm -f *
cd $DRUPAL_DIR
outfile=$BACKUP_DIR/$BACKUP_PREFIX.$uniqueFragment.tar.gz # FIXME is it gzipped?
echo "${uniqueFragment} performing drush dump to $outfile"
drush archive-dump --destination=$outfile
echo "${uniqueFragment} drush dump complete"

