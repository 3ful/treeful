from postgis/postgis
# need to enable raster extentions


COPY ./initialize-raster.sh /docker-entrypoint-initdb.d/initialize-raster.sh
# CREATE EXTENSION postgis_raster;
# SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';
# SELECT name, default_version,installed_version
# FROM pg_available_extensions WHERE name LIKE 'postgis%' or name LIKE 'address%';