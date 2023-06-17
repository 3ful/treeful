psql -c 'CREATE EXTENSION postgis_raster;'
psql -c 'SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';'
psql -c "SELECT name, default_version,installed_version FROM pg_available_extensions WHERE name LIKE 'postgis%' or name LIKE 'address%';"