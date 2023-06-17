#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Load PostGIS into both template_database and $POSTGRES_DB

echo "Loading PostGIS Raster extensions into $DB"
"${psql[@]}" --dbname="treeful-test" <<-'EOSQL'
	CREATE EXTENSION postgis_raster;
	SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';
EOSQL
