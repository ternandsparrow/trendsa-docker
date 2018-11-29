> Drupal stack to run the TrendSA website

## To run
Dependencies:
  1. docker 18.09
  1. docker-compose 1.17
  1. a `drush` dump (files and DB) of the site

Steps:
  1. copy the runner script
      ```bash
      cp start-or-restart.sh.example start-or-restart.sh
      chmod +x start-or-restart.sh
      ```
  1. edit the runner script `start-or-restart.sh` to define the needed sensitive environmental variables
      ```bash
      vim start-or-restart.sh
      ```
  1. start the stack
      ```bash
      ./start-or-restart.sh
      # or if you need to force a rebuild of the child docker images, which you should do after a `git pull`
      ./start-or-restart.sh --build
      ```
  1. copy the drush dump archive into the drush container
      ```bash
      docker cp /path/to/website.20181127_053515.tar.gz trendsadocker_drush_1:/tmp/
      ```
  1. exec into the drush container
      ```bash
      docker exec -it trendsadocker_drush_1 sh
      ```
  1. create the mysql DB
      ```bash
      # in drush container
      echo 'CREATE DATABASE website;' | mysql -u root -p$MYSQL_PASS -h mysql
      ```
  1. restore the drush archive
      ```bash
      # still in drush container
      drush arr /tmp/website.20181127_053515.tar.gz \
        --db-url=mysql://root:$MYSQL_PASS@mysql/website \
        --destination=$DRUPAL_DIR \
        --overwrite
      ```
  1. delete the dump archive
      ```bash
      # still in drush container
      rm /tmp/website.20181127_053515.tar.gz
      ```
  1. exit the drush container
      ```bash
      # still in drush container
      exit
      ```
  1. copy the `settings.php` file out to the host, so we can edit it
      ```bash
      docker cp trendsadocker_drush_1:/var/www/html/sites/default/settings.php /tmp/settings.php
      sudo chown `id -u` /tmp/settings.php
      chmod 644 /tmp/settings.php
      ```
  1. edit the `/tmp/settings.php` file you have on your host to replace the old DB config (top of the file) with the new DB config at the bottom of the file. Then save it.
  1. copy the `settings.php` file from the host back into the container
      ```bash
      docker cp /tmp/settings.php trendsadocker_drush_1:/var/www/html/sites/default/settings.php
      ```
  1. open your browser on the host to view the Drupal site: http://localhost:8080, or whatever you set `EXTERNAL_LISTEN_PORT` to

## Stopping the stack
The stack is designed to always keep running, even after a server restart, until you manually stop it. The data for mysql, drupal and the backups are stored in Docker data volumes. This means you can stop and destroy the stack, but **keep the data** with:
```bash
docker-compose down
```

If you want to completely clean up and have the **data volumes also removed**, you can do this with:
```bash
docker-compose down --volumes
```

## Creating a static copy of the site

In the case where we need to keep the site running but we don't expect any new content, we can dump it to a static copy and run that on something simple like AWS S3.

You can get the static site by:
```bash
wget --mirror http://localhost:8080
```

This will write the site to a `localhost:8080` directory. You can then upload the data to S3 with something like (not tested):
```bash
# upload all the top level HTML pages and force content-type
find . -type f -maxdepth 1 -exec aws s3 cp '{}' s3://trendsa.org.au --content-type="text/html; charset=utf-8" --acl=public-read \;
# upload the rest, which does ok with guessing content-type
aws s3 sync . s3://trendsa.org.au --acl=public-read
```

Then make sure that S3 bucket is enabled as a static website and set the home page to `index.html`.

This isn't perfect but it's pretty good. It doesn't handle redirects from querystrings like the footer links to copyright, disclaimer, etc. The content is there but the links don't work. Oh well.
