FROM mdillon/postgis:9.6

RUN apt-get update \
  && apt-get install -y --no-install-recommends postgresql-contrib \
  && rm -rf /var/lib/apt/lists/*

COPY migrate.sh /

ENTRYPOINT ["/migrate.sh"]
