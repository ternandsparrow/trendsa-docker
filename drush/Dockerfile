FROM drush/drush:8-alpine

ADD *.sh /
RUN \
  chmod +x /*.sh && \
  apk add --no-cache gzip

ENTRYPOINT ["/entrypoint.sh"]
CMD [""]
