#!/bin/bash
OLD_PGPASSWORD=${PGPASSWORD}

echo "REFERENCE_DATA_DATABASE::Retrieve Facility Type IDs"
export PGPASSWORD=${REFERENCE_DATA_DATABASE_PASSWORD}
facility_types=$(psql -X -A -h ${REFERENCE_DATA_DATABASE_URL} -U ${REFERENCE_DATA_DATABASE_USER} -d open_lmis -t -c "SELECT id FROM referencedata.facility_types")

echo "REQUISITION_DATABASE:: Retrieve Requisition Template and Program IDs"
export PGPASSWORD=${REQUISITION_DATABASE_PASSWORD}
templates=$(psql -X -A -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} -d open_lmis -F , -t -c "SELECT id, programId FROM requisition.requisition_templates")

echo "BASH::Create requisition template assignments"
if [ -f assignments.sql ]; then
  rm assignments.sql
fi

for facility_type_id in ${facility_types}; do
  while IFS=, read -r template_id program_id; do
    ROW_ID=$(cat /proc/sys/kernel/random/uuid)
    echo "INSERT INTO requisition.requisition_template_assignments(id, programId, facilityTypeId, templateId) VALUES ('${ROW_ID}', '${program_id}', '${facility_type_id}', '${template_id}')" >> assignments.sql
  done <<< ${templates}
done

echo "REQUISITION_DATABASE::Apply assignments to requisition database"
psql -X -A -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} -d open_lmis < assignments.sql

echo "REQUISITION_DATABASE::Remove programId column from requisition template table"
psql -X -A -h ${REQUISITION_DATABASE_URL} -U ${REQUISITION_DATABASE_USER} -d open_lmis -c "ALTER TABLE requisition.requisition_templates DROP COLUMN programId"

export PGPASSWORD=${OLD_PGPASSWORD}
