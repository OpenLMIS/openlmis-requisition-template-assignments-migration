#!/bin/bash
OLD_PGPASSWORD=${PGPASSWORD}

echo "REFERENCE_DATA_DATABASE::Retrieve Program names"
export PGPASSWORD=${REFERENCE_DATA_DATABASE_PASSWORD}
program_names=$(psql -X -A -h ${REFERENCE_DATA_DATABASE_URL} -U ${REFERENCE_DATA_DATABASE_USER} -d open_lmis -F , -t -c "SELECT id, name FROM referencedata.programs")

echo "BASH::Create requisition template names migration"
if [ -f names.sql ]; then
  rm names.sql
fi

while IFS=, read -r id name; do
  echo "UPDATE requisition.requisition_templates SET name='${name}' WHERE programId = '${id}';" >> names.sql
done <<< ${program_names}

echo "REQUISITION_DATABASE::Apply migration"
export PGPASSWORD=${REQUISITION_DATABASE_PASSWORD}
psql -X -A -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} -d open_lmis < names.sql

export PGPASSWORD=${OLD_PGPASSWORD}
