#!/bin/bash

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

./set_template_names.sh
./create_assignments.sh
