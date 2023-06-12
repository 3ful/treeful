from postgis/postgis
# need to enable raster extentions
RUN psql -c 'CREATE EXTENSION postgis_raster;'
RUN psql -c 'SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';'
RUN psql -c "SELECT name, default_version,installed_version
# FROM pg_available_extensions WHERE name LIKE 'postgis%' or name LIKE 'address%';"

# CREATE EXTENSION postgis_raster;
# SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';
# SELECT name, default_version,installed_version
# FROM pg_available_extensions WHERE name LIKE 'postgis%' or name LIKE 'address%';