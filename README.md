> Drupal stack to run the TrendSA website

## To run
Dependencies:
  1. docker 18.09
  1. docker-compose 1.17
  1. a `drush` dump (files and DB) of the site

Steps:
  1. start the stack
      ```bash
      docker-compose up -d
      ```
  1. copy the drush dump archive into the drupal container
      ```bash
      docker cp /path/to/website.20181127_053515.tar.gz trendsadocker_drupal_1:/tmp/
      ```
  1. exec into the drupal container
      ```bash
      docker exec -it trendsadocker_drupal_1 bash
      ```
  1. install `drush` into the container
      ```bash
      # in the drupal container
      curl -L https://github.com/drush-ops/drush/releases/download/8.1.18/drush.phar > /usr/local/bin/drush
      chmod +x /usr/local/bin/drush
      drush --version
      ```
  1. install `mysql` client
      ```bash
      # still in drupal container
      apt-get update
      apt-get -y install mysql-client
      mysql --version
      ```
  1. create the mysql DB
      ```bash
      # still in drupal container
      echo 'CREATE DATABASE website;' | mysql -u root -pexample -h mysql
      ```
  1. restore the drush archive
      ```bash
      # still in drupal container
      cd /var/www
      drush arr /tmp/website.20181127_053515.tar.gz \
        --db-url=mysql://root:example@mysql/website \
        --destination=/var/www/html \
        --overwrite
      ```
  1. delete the dump archive
      ```bash
      rm /tmp/website.20181127_053515.tar.gz
      ```
  1. exit the drupal container
      ```bash
      exit
      ```
  1. copy the `settings.php` file out to the host, so we can edit it
      ```bash
      docker cp trendsadocker_drupal_1:/var/www/html/sites/default/settings.php /tmp/settings.php
      sudo chown `id -u` /tmp/settings.php
      chmod 644 /tmp/settings.php
      ```
  1. edit the `/tmp/settings.php` file you have on your host to replace the old DB config (top of the file) with the new DB config at the bottom of the file. Then save it.
  1. copy the `settings.php` file from the host back into the drupal container
      ```bash
      docker cp /tmp/settings.php trendsadocker_drupal_1:/var/www/html/sites/default/settings.php
      ```
  1. open your browser on the host to view the Drupal site: http://localhost:8080

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
