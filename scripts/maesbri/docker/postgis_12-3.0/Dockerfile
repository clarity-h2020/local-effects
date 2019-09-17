FROM postgres:12
MAINTAINER Mike Dillon <mike@appropriate.io>

ENV POSTGIS_MAJOR 3
ENV POSTGIS_VERSION 3.0.0~alpha4+dfsg-2~216.gitf249e94.pgdg100+1

## add the postgresql testing repository in order to be able to install postgis 3 for postgresql 12
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg-testing main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
           postgis=$POSTGIS_VERSION \
           postgresql-contrib-$PG_MAJOR \
           postgresql-$PG_MAJOR-pgrouting \
           postgresql-$PG_MAJOR-pgrouting-scripts \
           postgresql-$PG_MAJOR-ogr-fdw \           
           postgresql-$PG_MAJOR-unit \
           postgresql-$PG_MAJOR-partman \
           postgresql-$PG_MAJOR-hypopg \
           postgresql-$PG_MAJOR-pg-qualstats \
           postgresql-$PG_MAJOR-pg-stat-kcache \
           postgresql-$PG_MAJOR-powa \
           pgtop \
      && apt-get upgrade -y \
      && rm -rf /var/lib/apt/lists/*

#NOTE: All this is to be added in the future (when there is support for postgresql v12)
#These three citus extensions are not yet available for postgresql-12
#postgresql-$PG_MAJOR-citus \
#postgresql-$PG_MAJOR-cstore-fdw \
#postgresql-$PG_MAJOR-cron \

## MADlibd (Big Data Machine Learning in SQL) support for postgresql 12 is not available yet: https://madlib.apache.org/index.html

## PGStrom: check how to install this

RUN echo "5"

RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY ./update-postgis.sh /usr/local/bin