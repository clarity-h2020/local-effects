--- Drop temporary tables if they exist
DROP TABLE IF EXISTS tmp_ua;
DROP TABLE IF EXISTS tmp_ua_gridded_land_use_area;
DROP TABLE IF EXISTS tmp_ua_gridded_agricultural_areas;
DROP TABLE IF EXISTS tmp_ua_gridded_basins;
DROP TABLE IF EXISTS tmp_ua_gridded_built_open_spaces;
DROP TABLE IF EXISTS tmp_ua_gridded_built_up;
DROP TABLE IF EXISTS tmp_ua_gridded_dense_urban_fabric;
DROP TABLE IF EXISTS tmp_ua_gridded_low_urban_fabric;
DROP TABLE IF EXISTS tmp_ua_gridded_medium_urban_fabric;
DROP TABLE IF EXISTS tmp_ua_gridded_public_military_industrial;
DROP TABLE IF EXISTS tmp_ua_gridded_railways;
DROP TABLE IF EXISTS tmp_ua_gridded_roads;
DROP TABLE IF EXISTS tmp_ua_gridded_streams;
DROP TABLE IF EXISTS tmp_ua_gridded_trees;
DROP TABLE IF EXISTS tmp_ua_gridded_vegetation;
DROP TABLE IF EXISTS tmp_ua_gridded_water;

--- Temporary Urban Atlas table for current city being processed
CREATE TABLE tmp_ua (
    fid SERIAL NOT NULL,
    ---city_name CHARACTER VARYING(254) NOT NULL, --- field: cities
    ---city_code CHARACTER VARYING(7) NOT NULL,
    ---countrycode CHARACTER VARYING(2) NOT NULL,    
    ftcode CHARACTER VARYING(7) NOT NULL, --- Feature Type Code: code2012
    geom GEOMETRY(POLYGON,3035),

    CONSTRAINT tmp_ua_fid_pkey PRIMARY KEY (fid)
);

DROP INDEX IF EXISTS tmp_ua_fid_idx;
DROP INDEX IF EXISTS tmp_ua_ftcode_idx;
DROP INDEX IF EXISTS tmp_ua_geom_idx;
CREATE INDEX tmp_ua_fid_idx ON tmp_ua USING gist (fid);
CREATE INDEX tmp_ua_ftcode_idx ON tmp_ua USING gist (ftcode);
CREATE INDEX tmp_ua_geom_idx ON tmp_ua USING gist (geom);

--- TABLE: Temporal City Grid (as a subset of the European Reference Grid (500m) table)
DROP TABLE IF EXISTS tmp_city_grid CASCADE;
CREATE TABLE tmp_city_grid (
    fid SERIAL NOT NULL,
    geom GEOMETRY(POLYGON,3035) NOT NULL,

    CONSTRAINT tmp_city_grid_fid_pkey PRIMARY KEY (fid)
);
DROP INDEX IF EXISTS tmp_city_grid_fid_idx;
DROP INDEX IF EXISTS tmp_city_grid_geom_idx;
DROP INDEX IF EXISTS tmp_city_grid_geohash_idx;
CREATE INDEX tmp_city_grid_fid_idx ON tmp_city_grid USING gist (fid);
CREATE INDEX tmp_city_grid_geom_idx ON tmp_city_grid USING gist (geom);
CREATE INDEX tmp_city_grid_geohash_idx ON tmp_city_grid (ST_GeoHash(ST_Transform(geom,4326)));

--- Create again all other temporary tables
SELECT create_table_like('ua_gridded_land_use_area', 'tmp_ua_gridded_land_use_area');
SELECT create_table_like('ua_gridded_agricultural_areas', 'tmp_ua_gridded_agricultural_areas');
SELECT create_table_like('ua_gridded_basins', 'tmp_ua_gridded_basins');
SELECT create_table_like('ua_gridded_built_open_spaces', 'tmp_ua_gridded_built_open_spaces');
SELECT create_table_like('ua_gridded_built_up', 'tmp_ua_gridded_built_up');
SELECT create_table_like('ua_gridded_dense_urban_fabric', 'tmp_ua_gridded_dense_urban_fabric');
SELECT create_table_like('ua_gridded_low_urban_fabric', 'tmp_ua_gridded_low_urban_fabric');
SELECT create_table_like('ua_gridded_medium_urban_fabric', 'tmp_ua_gridded_medium_urban_fabric');
SELECT create_table_like('ua_gridded_public_military_industrial', 'tmp_ua_gridded_public_military_industrial');
SELECT create_table_like('ua_gridded_railways', 'tmp_ua_gridded_railways');
SELECT create_table_like('ua_gridded_roads', 'tmp_ua_gridded_roads');
SELECT create_table_like('ua_gridded_streams', 'tmp_ua_gridded_streams');
SELECT create_table_like('ua_gridded_trees', 'tmp_ua_gridded_trees');
SELECT create_table_like('ua_gridded_vegetation', 'tmp_ua_gridded_vegetation');
SELECT create_table_like('ua_gridded_water', 'tmp_ua_gridded_water');