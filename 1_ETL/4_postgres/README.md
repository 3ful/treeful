# Deploy second DB on RPI for redundancy

* Change postgres Dockerfile image to 
from duvel/postgis:15-3.3
* on empty, remote DB run
pg_dump -C -h remotehost -U postgres treeful-test | psql -h localhost -U postgres treeful-test

