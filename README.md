# Requisition Template Migration (Cross-Service)

Cross service migration of requisition template and assignments

## Pre-requisites

* Already using OpenLMIS 3.2.X.
* Hosting OpenLMIS inside Docker with Docker Compose, and using PostgreSQL or AWS RDS as the database, with all OpenLMIS services using the same database instance.
* Requires administrator-level server access.

It is **strongly** suggested to run the migration on a staging/test server with a copy of production data first in order to verify the migration before running on production server.

## Migration instructions

Pre-planning: Schedule downtime to perform the upgrade; do the upgrade on a Test/Staging server in advance before Production.

1. Bring server offline (so no more edits to data will be accepted from users). Stop the OpenLMIS services (docker-compose down).
2. Take full database backup. (And make sure you have a backup of the code/services deployed as well so you could roll back if necessary.)
3. Upgrade to OpenLMIS 3.3 components (usual steps to change versions of components used in your ref-distro docker-compose.yml).
4. Start the server to run OpenLMIS and apply components migrations (docker-compose up).
5. After successful start bring server offline one more time (wait about 5 min to ensure that all migrations were applied).
6. Run the migration script. See section below for details.
7. Start the server to run OpenLMIS again (docker-compose up).
8. Run some manual tests to ensure the system is in good health (try viewing a requisition template, check if each template is related with all facility types).
9. Bring server online (begin accepting outside traffic from users again).


## Usage

This image is based off of openlmis/run-sql, and so the environment variables needed for that image are needed here. In particular, you need the configuration file found [here](https://github.com/OpenLMIS/openlmis-ref-distro/blob/master/settings-sample.env).

Next simply run the migration script using Docker:

```bash
docker run --rm --env-file settings.env openlmis/requisition-template-migration
```

That's it - the migration will run and give you output about its progress.

## Building

The Docker image is built on Docker Hub. In order to build it locally, simply run:

```bash
docker build -t openlmis/requisition-template-migration .
```

## Script details

This script performs the migration of requisition template names and assignments to handle new requisition template mechanism.

The migration executes two steps:

### Step 1 - set default requisition template names

From OpenLMIS 3.3 each requisition template will have a name field that must be set. To ensure that the system will work correctly after first start the script will set a default name for each requisition template. The default name will be equal to related program name.

We match a requisition template with a program by `id` column from the `programs` table and `programId` column from the `requisition_templates` table.

### Step 2 - set default requisition template assignments

In this step, we create default requisition template assignments to handle new requisitions. To match this requirement by default we assign each active requisition template to all facility types that are in the database. After this step there should be X * Y records in the `requisition_template_assignments` table where X is equal to number of active templates in the `requisition_templates` table and Y is equal to number of facility types.

See further information:

JIRA Ticket: [OLMIS-3929](https://openlmis.atlassian.net/browse/OLMIS-3929)

## Error reporting

If the script is run twice, it should not corrupt the data, since it does not modify the schema - we only update template name and recreate template assignments. Any additional data that was added in the meantime will be migrated.
