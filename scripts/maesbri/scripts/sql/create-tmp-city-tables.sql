--- Drop temporary tables if they exist
DROP TABLE IF EXISTS public.__land_use_area;
DROP TABLE IF EXISTS public.__agricultural_areas;
DROP TABLE IF EXISTS public.__basins;
DROP TABLE IF EXISTS public.__built_open_spaces;
DROP TABLE IF EXISTS public.__built_up;
DROP TABLE IF EXISTS public.__dense_urban_fabric;
DROP TABLE IF EXISTS public.__low_urban_fabric;
DROP TABLE IF EXISTS public.__medium_urban_fabric;
DROP TABLE IF EXISTS public.__public_military_industrial;
DROP TABLE IF EXISTS public.__railways;
DROP TABLE IF EXISTS public.__roads;
DROP TABLE IF EXISTS public.__streams;
DROP TABLE IF EXISTS public.__trees;
DROP TABLE IF EXISTS public.__vegetation;
DROP TABLE IF EXISTS public.__water;

DROP TABLE IF EXISTS public.__urban_atlas;
DROP TABLE IF EXISTS public.__street_trees;

--- Create again all temporary tables
SELECT create_table_like('land_use_area', '__land_use_area');
SELECT create_table_like('agricultural_areas', '__agricultural_areas');
SELECT create_table_like('basins', '__basins');
SELECT create_table_like('built_open_spaces', '__built_open_spaces');
SELECT create_table_like('built_up', '__built_up');
SELECT create_table_like('dense_urban_fabric', '__dense_urban_fabric');
SELECT create_table_like('low_urban_fabric', '__low_urban_fabric');
SELECT create_table_like('medium_urban_fabric', '__medium_urban_fabric');
SELECT create_table_like('public_military_industrial', '__public_military_industrial');
SELECT create_table_like('railways', '__railways');
SELECT create_table_like('roads', '__roads');
SELECT create_table_like('streams', '__streams');
SELECT create_table_like('trees', '__trees');
SELECT create_table_like('vegetation', '__vegetation');
SELECT create_table_like('water', '__water');


--- Temporary Urban Atlas table for current city being processed
CREATE TABLE public.__urban_atlas (
    fid SERIAL NOT NULL,
    ---city_name CHARACTER VARYING(254) NOT NULL, --- field: cities
    ---city_code CHARACTER VARYING(7) NOT NULL,
    ---countrycode CHARACTER VARYING(2) NOT NULL,    
    featuretype_code CHARACTER VARYING(7) NOT NULL, --- field: code2012
    geom GEOMETRY(POLYGON,3035),

    CONSTRAINT __urban_atlas_fid_pkey PRIMARY KEY (fid)
);

DROP INDEX IF EXISTS __urban_atlas_fid_idx;
DROP INDEX IF EXISTS __urban_atlas_featuretype_code_idx;
DROP INDEX IF EXISTS __urban_atlas_geom_idx;
CREATE INDEX __urban_atlas_fid_idx ON public.__urban_atlas USING gist (fid);
CREATE INDEX __urban_atlas_featuretype_code_idx ON public.__urban_atlas USING gist (featuretype_code);
CREATE INDEX __urban_atlas_geom_idx ON public.__urban_atlas USING gist (geom);

--- Temporary Street Trees table for current city being processed
CREATE TABLE public.__street_trees (
    fid SERIAL NOT NULL,
    ---city_name CHARACTER VARYING(254) NOT NULL, --- field: cities
    ---city_code CHARACTER VARYING(7) NOT NULL,
    ---countrycode CHARACTER VARYING(2) NOT NULL,
    geom GEOMETRY(POLYGON,3035),

    CONSTRAINT __street_trees_fid_pkey PRIMARY KEY (fid)
);

DROP INDEX IF EXISTS __street_trees_fid_idx;
DROP INDEX IF EXISTS __street_trees_geom_idx;
CREATE INDEX __street_trees_fid_idx ON public.__street_trees USING gist (fid);
CREATE INDEX __street_trees_geom_idx ON public.__street_trees USING gist (geom);