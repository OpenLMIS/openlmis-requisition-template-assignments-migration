#!/bin/bash

set -e

if [ -z ${REFERENCE_DATA_DATABASE_URL+x} ]; then
  echo "The REFERENCE_DATA_DATABASE_URL variable is not set"
  exit -1
fi

if [ -z ${REFERENCE_DATA_DATABASE_USER+x} ]; then
  echo "The REFERENCE_DATA_DATABASE_USER variable is not set"
  exit -1
fi

if [ -z ${REFERENCE_DATA_DATABASE_PASSWORD+x} ]; then
  echo "The REFERENCE_DATA_DATABASE_PASSWORD variable is not set"
  exit -1
fi

if [ -z ${REQUISITION_DATABASE_URL+x} ]; then
  echo "The REQUISITION_DATABASE_URL variable is not set"
  exit -1
fi

if [ -z ${REQUISITION_DATABASE_USER+x} ]; then
  echo "The REQUISITION_DATABASE_USER variable is not set"
  exit -1
fi

if [ -z ${REQUISITION_DATABASE_PASSWORD+x} ]; then
  echo "The REQUISITION_DATABASE_PASSWORD variable is not set"
  exit -1
fi

if [ -f migration.sql ]; then
  rm migration.sql
fi

OLD_PGPASSWORD=${PGPASSWORD}
PSQL="psql -X --single-transaction --set AUTOCOMMIT=off --set ON_ERROR_STOP=on --no-align -t --field-separator , --quiet -d open_lmis"

export PGPASSWORD=${REFERENCE_DATA_DATABASE_PASSWORD}
echo "Read program names (the reference data database)"
${PSQL} -h ${REFERENCE_DATA_DATABASE_URL} -U ${REFERENCE_DATA_DATABASE_USER} -c "SELECT id, name FROM referencedata.programs" > program_names.csv

echo "Read facility type ids (the reference data database)"
${PSQL} -h ${REFERENCE_DATA_DATABASE_URL} -U ${REFERENCE_DATA_DATABASE_USER} -c "SELECT id FROM referencedata.facility_types" > facility_type_ids.csv

export PGPASSWORD=${REQUISITION_DATABASE_PASSWORD}
echo "Read requisition template details (the requisition database)"
${PSQL} -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} -c "SELECT id, programId FROM requisition.requisition_templates" > template_details.csv

echo "Create migration file"
echo "Add steps to update requisition template names (the requisition database)"
while IFS=, read -r id name ; do
  echo "UPDATE requisition.requisition_templates SET name='${name}' WHERE programId = '${id}';" >> migration.sql
done < program_names.csv

echo "Add step to clear current requisition template assignments (the requisition database)"
echo "TRUNCATE TABLE requisition.requisition_template_assignments;" >> migration.sql

echo "Add steps to insert requisition template assignments (the requisition database)"
while IFS=, read -r template_id program_id ; do
  while IFS=, read -r facility_type_id ; do
    ROW_ID=$(cat /proc/sys/kernel/random/uuid)
    echo "INSERT INTO requisition.requisition_template_assignments(id, programId, facilityTypeId, templateId) VALUES ('${ROW_ID}', '${program_id}', '${facility_type_id}', '${template_id}');" >> migration.sql
  done < facility_type_ids.csv
done < template_details.csv

echo "Apply migration (the requisition database)"
${PSQL} -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} < migration.sql

export PGPASSWORD=${OLD_PGPASSWORD}
