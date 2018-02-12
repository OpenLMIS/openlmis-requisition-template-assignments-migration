FROM mdillon/postgis:9.6

RUN apt-get update \
  && apt-get install -y --no-install-recommends postgresql-contrib \
  && rm -rf /var/lib/apt/lists/*

COPY create_assignments.sh /
COPY set_template_names.sh /
COPY run_migration.sh /

ENTRYPOINT ["/run_migration.sh"]
