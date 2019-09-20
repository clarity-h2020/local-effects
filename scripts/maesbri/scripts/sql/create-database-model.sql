--- TABLE: European Reference Grid (500m)
DROP TABLE IF EXISTS laea_etrs_500m CASCADE;
CREATE TABLE laea_etrs_500m (
    fid SERIAL NOT NULL,
    cellcode CHARACTER VARYING(254) NOT NULL, -- String identifier of this cell
    eorigin INTEGER NOT NULL, -- Easting origin for this cell
    norigin INTEGER NOT NULL, -- Northin origin for this cell
    geom GEOMETRY(POLYGON,3035) NOT NULL,

	UNIQUE (fid,eorigin,norigin),
    CONSTRAINT laea_etrs_500m_fid_pkey PRIMARY KEY (fid, eorigin, norigin)
) PARTITION BY RANGE (eorigin);

CREATE TABLE laea_etrs_500m_e09 PARTITION OF laea_etrs_500m FOR VALUES FROM (MINVALUE) TO (9000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e09n09 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e09n17 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e09n26 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e09n35 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e09n44 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e09n54 PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e09nxx PARTITION OF laea_etrs_500m_e09 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e17 PARTITION OF laea_etrs_500m FOR VALUES FROM (9001) TO (17000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e17n09 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e17n17 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e17n26 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e17n35 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e17n44 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e17n54 PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e17nxx PARTITION OF laea_etrs_500m_e17 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e25 PARTITION OF laea_etrs_500m FOR VALUES FROM (17001) TO (25000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e25n09 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e25n17 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e25n26 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e25n35 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e25n44 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e25n54 PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e25nxx PARTITION OF laea_etrs_500m_e25 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e33 PARTITION OF laea_etrs_500m FOR VALUES FROM (25001) TO (33000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e33n09 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e33n17 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e33n26 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e33n35 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e33n44 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e33n54 PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e33nxx PARTITION OF laea_etrs_500m_e33 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e41 PARTITION OF laea_etrs_500m FOR VALUES FROM (33001) TO (41000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e41n09 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e41n17 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e41n26 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e41n35 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e41n44 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e41n54 PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e41nxx PARTITION OF laea_etrs_500m_e41 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e49 PARTITION OF laea_etrs_500m FOR VALUES FROM (41001) TO (49000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e49n09 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e49n17 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e49n26 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e49n35 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e49n44 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e49n54 PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e49nxx PARTITION OF laea_etrs_500m_e49 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e57 PARTITION OF laea_etrs_500m FOR VALUES FROM (49001) TO (57000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e57n09 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e57n17 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e57n26 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e57n35 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e57n44 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e57n54 PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e57nxx PARTITION OF laea_etrs_500m_e57 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_e66 PARTITION OF laea_etrs_500m FOR VALUES FROM (57001) TO (66000) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_e66n09 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_e66n17 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_e66n26 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_e66n35 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_e66n44 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_e66n54 PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_e66nxx PARTITION OF laea_etrs_500m_e66 FOR VALUES FROM (54001) TO (MAXVALUE);

CREATE TABLE laea_etrs_500m_exx PARTITION OF laea_etrs_500m FOR VALUES FROM (66001) TO (MAXVALUE) PARTITION BY RANGE (norigin);
CREATE TABLE laea_etrs_500m_exxn09 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (MINVALUE) TO (9000);
CREATE TABLE laea_etrs_500m_exxn17 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (9001) TO (17000);
CREATE TABLE laea_etrs_500m_exxn26 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (17001) TO (26000);
CREATE TABLE laea_etrs_500m_exxn35 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (26001) TO (35000);
CREATE TABLE laea_etrs_500m_exxn44 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (35001) TO (44000);
CREATE TABLE laea_etrs_500m_exxn54 PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (44001) TO (54000);
CREATE TABLE laea_etrs_500m_exxnxx PARTITION OF laea_etrs_500m_exx FOR VALUES FROM (54001) TO (MAXVALUE);
 


DROP INDEX IF EXISTS laea_etrs_500m_fid_idx;
DROP INDEX IF EXISTS laea_etrs_500m_cellcode_idx;
DROP INDEX IF EXISTS laea_etrs_500m_geom_idx;
DROP INDEX IF EXISTS laea_etrs_500m_geohash_idx;
DROP INDEX IF EXISTS laea_etrs_500m_enorigin_idx;
CREATE INDEX laea_etrs_500m_fid_idx ON laea_etrs_500m USING gist (fid);
CREATE INDEX laea_etrs_500m_cellcode_idx ON laea_etrs_500m USING gist (cellcode);
CREATE INDEX laea_etrs_500m_geom_idx ON laea_etrs_500m USING gist (geom);
CREATE INDEX laea_etrs_500m_geohash_idx ON laea_etrs_500m (ST_GeoHash(ST_Transform(geom,4326))); --- The geohash algorithm only works on data in geographic (longitude/latitude) coordinates, so we need to transform the geometries (to EPSG:4326, which is longitude/latitude) at the same time as we hash them.
CREATE INDEX laea_etrs_500m_enorigin_idx ON laea_etrs_500m USING gist (eorigin,norigin);

---CLUSTER laea_etrs_500m USING laea_etrs_500m_geom_idx;
---CLUSTER laea_etrs_500m USING laea_etrs_500m_geohash_idx; --- Clustering by GeoHash: https://postgis.net/workshops/postgis-intro/clusterindex.html
---CLUSTER laea_etrs_500m USING laea_etrs_500m_enorigin_idx;

--- TABLE: City
DROP TABLE IF EXISTS city CASCADE;
CREATE TABLE city (
    id SERIAL NOT NULL,
    name CHARACTER VARYING(32) NOT NULL,
    code CHARACTER VARYING(7) UNIQUE NOT NULL,
    countrycode CHARACTER VARYING(3) NOT NULL,
    population INTEGER NOT NULL DEFAULT 0,
    boundary GEOMETRY(MULTIPOLYGON,3035) NOT NULL,
    bbox GEOMETRY(POLYGON,3035) NOT NULL,

    CONSTRAINT city_id_pkey PRIMARY KEY (id)
);

DROP INDEX IF EXISTS city_id_idx;
DROP INDEX IF EXISTS city_name_idx;
DROP INDEX IF EXISTS city_code_idx;
DROP INDEX IF EXISTS city_countrycode_idx;
DROP INDEX IF EXISTS city_bbox_idx;
DROP INDEX IF EXISTS city_boundary_idx;
CREATE INDEX city_id_idx ON city USING gist (id);
CREATE INDEX city_name_idx ON city USING gist (name);
CREATE INDEX city_code_idx ON city USING gist (code);
CREATE INDEX city_countrycode_idx ON city USING gist (countrycode);
CREATE INDEX city_bbox_idx ON city USING gist (bbox);
CREATE INDEX city_boundary_idx ON city USING gist (boundary);

CREATE OR REPLACE FUNCTION get_city_id_by_code(citycode text) RETURNS INTEGER AS $$
    SELECT c.id FROM city c WHERE c.code = citycode;
$$ LANGUAGE SQL;

--- TABLE: Area Land Use Grid
DROP TABLE IF EXISTS ua_gridded_land_use_area CASCADE;
CREATE TABLE ua_gridded_land_use_area (
    id SERIAL NOT NULL,
    cellid BIGINT NOT NULL,
    cityid BIGINT NOT NULL,
    
    water REAL NOT NULL DEFAULT 0.0,
    roads REAL NOT NULL DEFAULT 0.0,
    railways REAL NOT NULL DEFAULT 0.0,
    trees REAL NOT NULL DEFAULT 0.0,
    vegetation REAL NOT NULL DEFAULT 0.0,
    agricultural REAL NOT NULL DEFAULT 0.0,
    built_up REAL NOT NULL DEFAULT 0.0,
    built_open_spaces REAL NOT NULL DEFAULT 0.0,
    dense_urban_fabric REAL NOT NULL DEFAULT 0.0,
    medium_urban_fabric REAL NOT NULL DEFAULT 0.0,
    low_urban_fabric REAL NOT NULL DEFAULT 0.0,
    public_military_industrial REAL NOT NULL DEFAULT 0.0,
    streams REAL NOT NULL DEFAULT 0.0,
    basins REAL NOT NULL DEFAULT 0.0,

    CONSTRAINT ua_gridded_land_use_area_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_land_use_area_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_land_use_area_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_land_use_area_id_idx;
DROP INDEX IF EXISTS ua_gridded_land_use_area_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_land_use_area_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_land_use_area_cityid_cellid_idx;
CREATE INDEX ua_gridded_land_use_area_id_idx ON ua_gridded_land_use_area USING gist (id);
CREATE INDEX ua_gridded_land_use_area_cellid_idx ON ua_gridded_land_use_area USING gist (cellid);
CREATE INDEX ua_gridded_land_use_area_cityid_idx ON ua_gridded_land_use_area USING gist (cityid);
CREATE INDEX ua_gridded_land_use_area_cityid_cellid_idx ON ua_gridded_land_use_area USING gist (cityid, cellid);

---CLUSTER ua_gridded_land_use_area USING ua_gridded_land_use_area_id_idx;

--- TABLE: Agricultural Areas
DROP TABLE IF EXISTS ua_gridded_agricultural_areas CASCADE;
CREATE TABLE ua_gridded_agricultural_areas (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.11,
    emissivity REAL NOT NULL DEFAULT 0.95,
    transmissivity REAL NOT NULL DEFAULT 0.25,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.1,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT ua_gridded_agricultural_areas_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_agricultural_areas_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_agricultural_areas_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_agricultural_areas_id_idx;
DROP INDEX IF EXISTS ua_gridded_agricultural_areas_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_agricultural_areas_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_agricultural_areas_geom_idx;
DROP INDEX IF EXISTS ua_gridded_agricultural_areas_geohash_idx;
CREATE INDEX ua_gridded_agricultural_areas_id_idx ON ua_gridded_agricultural_areas USING gist (id);
CREATE INDEX ua_gridded_agricultural_areas_cityid_idx ON ua_gridded_agricultural_areas USING gist (cityid);
CREATE INDEX ua_gridded_agricultural_areas_cellid_idx ON ua_gridded_agricultural_areas USING gist (cellid);
CREATE INDEX ua_gridded_agricultural_areas_geom_idx ON ua_gridded_agricultural_areas USING gist (geom);
CREATE INDEX ua_gridded_agricultural_areas_geohash_idx ON ua_gridded_agricultural_areas (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Basins
DROP TABLE IF EXISTS ua_gridded_basins CASCADE;
CREATE TABLE ua_gridded_basins(
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    CONSTRAINT ua_gridded_basins_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_basins_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_basins_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_basins_id_idx;
DROP INDEX IF EXISTS ua_gridded_basins_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_basins_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_basins_geom_idx;
DROP INDEX IF EXISTS ua_gridded_basins_geohash_idx;
CREATE INDEX ua_gridded_basins_id_idx ON ua_gridded_basins USING gist (id);
CREATE INDEX ua_gridded_basins_cityid_idx ON ua_gridded_basins USING gist (cityid);
CREATE INDEX ua_gridded_basins_cellid_idx ON ua_gridded_basins USING gist (cellid);
CREATE INDEX ua_gridded_basins_geom_idx ON ua_gridded_basins USING gist (geom);
CREATE INDEX ua_gridded_basins_geohash_idx ON ua_gridded_basins (ST_GeoHash(ST_Transform(geom,4326)));


--- TABLE: Built Open Spaces
DROP TABLE IF EXISTS ua_gridded_built_open_spaces CASCADE;
CREATE TABLE ua_gridded_built_open_spaces (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    area REAL,
    perimeter REAL,
    albedo REAL NOT NULL DEFAULT 0.45,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 0.05,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.75,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_building REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT ua_gridded_built_open_spaces_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_built_open_spaces_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_built_open_spaces_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_built_open_spaces_id_idx;
DROP INDEX IF EXISTS ua_gridded_built_open_spaces_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_built_open_spaces_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_built_open_spaces_geom_idx;
DROP INDEX IF EXISTS ua_gridded_built_open_spaces_geohash_idx;
CREATE INDEX ua_gridded_built_open_spaces_id_idx ON ua_gridded_built_open_spaces USING gist (id);
CREATE INDEX ua_gridded_built_open_spaces_cityid_idx ON ua_gridded_built_open_spaces USING gist (cityid);
CREATE INDEX ua_gridded_built_open_spaces_cellid_idx ON ua_gridded_built_open_spaces USING gist (cellid);
CREATE INDEX ua_gridded_built_open_spaces_geom_idx ON ua_gridded_built_open_spaces USING gist (geom);
CREATE INDEX ua_gridded_built_open_spaces_geohash_idx ON ua_gridded_built_open_spaces (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Built-Up
DROP TABLE IF EXISTS ua_gridded_built_up CASCADE;
CREATE TABLE ua_gridded_built_up (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),    
    
    albedo REAL NOT NULL DEFAULT 0.2,
    emissivity REAL NOT NULL DEFAULT 0.85,
    transmissivity REAL NOT NULL DEFAULT 0.01,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.9,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT ua_gridded_built_up_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_built_up_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_built_up_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)    
);

DROP INDEX IF EXISTS ua_gridded_built_up_id_idx;
DROP INDEX IF EXISTS ua_gridded_built_up_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_built_up_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_built_up_geom_idx;
DROP INDEX IF EXISTS ua_gridded_built_up_geohash_idx;
CREATE INDEX ua_gridded_built_up_id_idx ON ua_gridded_built_up USING gist (id);
CREATE INDEX ua_gridded_built_up_cityid_idx ON ua_gridded_built_up USING gist (cityid);
CREATE INDEX ua_gridded_built_up_cellid_idx ON ua_gridded_built_up USING gist (cellid);
CREATE INDEX ua_gridded_built_up_geom_idx ON ua_gridded_built_up USING gist (geom);
CREATE INDEX ua_gridded_built_up_geohash_idx ON ua_gridded_built_up (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Dense Urban Fabric
DROP TABLE IF EXISTS ua_gridded_dense_urban_fabric CASCADE;
CREATE TABLE ua_gridded_dense_urban_fabric (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.065,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.4,
    runoff_coefficient REAL NOT NULL DEFAULT 0.7,
    context REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT ua_gridded_dense_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_dense_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_dense_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_dense_urban_fabric_id_idx;
DROP INDEX IF EXISTS ua_gridded_dense_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_dense_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_dense_urban_fabric_geom_idx;
DROP INDEX IF EXISTS ua_gridded_dense_urban_fabric_geohash_idx;
CREATE INDEX ua_gridded_dense_urban_fabric_id_idx ON ua_gridded_dense_urban_fabric USING gist (id);
CREATE INDEX ua_gridded_dense_urban_fabric_cityid_idx ON ua_gridded_dense_urban_fabric USING gist (cityid);
CREATE INDEX ua_gridded_dense_urban_fabric_cellid_idx ON ua_gridded_dense_urban_fabric USING gist (cellid);
CREATE INDEX ua_gridded_dense_urban_fabric_geom_idx ON ua_gridded_dense_urban_fabric USING gist (geom);
CREATE INDEX ua_gridded_dense_urban_fabric_geohash_idx ON ua_gridded_dense_urban_fabric (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Low Urban Fabric
DROP TABLE IF EXISTS ua_gridded_low_urban_fabric CASCADE;
CREATE TABLE ua_gridded_low_urban_fabric (
    id SERIAL NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,

    albedo REAL NOT NULL DEFAULT 0.15,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.4,
    context REAL NOT NULL DEFAULT 0.5,

    CONSTRAINT ua_gridded_low_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_low_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_low_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)
);

DROP INDEX IF EXISTS ua_gridded_low_urban_fabric_id_idx;
DROP INDEX IF EXISTS ua_gridded_low_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_low_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_low_urban_fabric_geom_idx;
DROP INDEX IF EXISTS ua_gridded_low_urban_fabric_geohash_idx;
CREATE INDEX ua_gridded_low_urban_fabric_id_idx ON ua_gridded_low_urban_fabric USING gist (id);
CREATE INDEX ua_gridded_low_urban_fabric_cityid_idx ON ua_gridded_low_urban_fabric USING gist (cityid);
CREATE INDEX ua_gridded_low_urban_fabric_cellid_idx ON ua_gridded_low_urban_fabric USING gist (cellid);
CREATE INDEX ua_gridded_low_urban_fabric_geom_idx ON ua_gridded_low_urban_fabric USING gist (geom);
CREATE INDEX ua_gridded_low_urban_fabric_geohash_idx ON ua_gridded_low_urban_fabric (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Medium Urban Fabric
DROP TABLE IF EXISTS ua_gridded_medium_urban_fabric CASCADE;
CREATE TABLE ua_gridded_medium_urban_fabric (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.11,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.2,
    runoff_coefficient REAL NOT NULL DEFAULT 0.5,
    context REAL NOT NULL DEFAULT 0.8,

    CONSTRAINT ua_gridded_medium_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_medium_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_medium_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)    
);

DROP INDEX IF EXISTS ua_gridded_medium_urban_fabric_id_idx;
DROP INDEX IF EXISTS ua_gridded_medium_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_medium_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_medium_urban_fabric_geom_idx;
DROP INDEX IF EXISTS ua_gridded_medium_urban_fabric_geohash_idx;
CREATE INDEX ua_gridded_medium_urban_fabric_id_idx ON ua_gridded_medium_urban_fabric USING gist (id);
CREATE INDEX ua_gridded_medium_urban_fabric_cityid_idx ON ua_gridded_medium_urban_fabric USING gist (cityid);
CREATE INDEX ua_gridded_medium_urban_fabric_cellid_idx ON ua_gridded_medium_urban_fabric USING gist (cellid);
CREATE INDEX ua_gridded_medium_urban_fabric_geom_idx ON ua_gridded_medium_urban_fabric USING gist (geom);
CREATE INDEX ua_gridded_medium_urban_fabric_geohash_idx ON ua_gridded_medium_urban_fabric (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Public, Military and Industrial
DROP TABLE IF EXISTS ua_gridded_public_military_industrial CASCADE;
CREATE TABLE ua_gridded_public_military_industrial (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.13,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.5,
    context REAL NOT NULL DEFAULT 0.5,

    CONSTRAINT ua_gridded_public_military_industrial_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_public_military_industrial_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_public_military_industrial_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)        
);

DROP INDEX IF EXISTS ua_gridded_public_military_industrial_id_idx;
DROP INDEX IF EXISTS ua_gridded_public_military_industrial_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_public_military_industrial_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_public_military_industrial_geom_idx;
DROP INDEX IF EXISTS ua_gridded_public_military_industrial_geohash_idx;
CREATE INDEX ua_gridded_public_military_industrial_id_idx ON ua_gridded_public_military_industrial USING gist (id);
CREATE INDEX ua_gridded_public_military_industrial_cityid_idx ON ua_gridded_public_military_industrial USING gist (cityid);
CREATE INDEX ua_gridded_public_military_industrial_cellid_idx ON ua_gridded_public_military_industrial USING gist (cellid);
CREATE INDEX ua_gridded_public_military_industrial_geom_idx ON ua_gridded_public_military_industrial USING gist (geom);
CREATE INDEX ua_gridded_public_military_industrial_geohash_idx ON ua_gridded_public_military_industrial (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Railways
DROP TABLE IF EXISTS ua_gridded_railways CASCADE;
CREATE TABLE ua_gridded_railways (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.2,
    emissivity REAL NOT NULL DEFAULT 0.85,
    transmissivity REAL NOT NULL DEFAULT 0.15,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.2,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT ua_gridded_railways_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_railways_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_railways_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)       
);

DROP INDEX IF EXISTS ua_gridded_railways_id_idx;
DROP INDEX IF EXISTS ua_gridded_railways_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_railways_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_railways_geom_idx;
DROP INDEX IF EXISTS ua_gridded_railways_geohash_idx;
CREATE INDEX ua_gridded_railways_id_idx ON ua_gridded_railways USING gist (id);
CREATE INDEX ua_gridded_railways_cityid_idx ON ua_gridded_railways USING gist (cityid);
CREATE INDEX ua_gridded_railways_cellid_idx ON ua_gridded_railways USING gist (cellid);
CREATE INDEX ua_gridded_railways_geom_idx ON ua_gridded_railways USING gist (geom);
CREATE INDEX ua_gridded_railways_geohash_idx ON ua_gridded_railways (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Roads
DROP TABLE IF EXISTS ua_gridded_roads CASCADE;
CREATE TABLE ua_gridded_roads (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.1,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 0.15,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.9,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_building REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT ua_gridded_roads_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_roads_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_roads_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)      
);

DROP INDEX IF EXISTS ua_gridded_roads_id_idx;
DROP INDEX IF EXISTS ua_gridded_roads_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_roads_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_roads_geom_idx;
DROP INDEX IF EXISTS ua_gridded_roads_geohash_idx;
CREATE INDEX ua_gridded_roads_id_idx ON ua_gridded_roads USING gist (id);
CREATE INDEX ua_gridded_roads_cityid_idx ON ua_gridded_roads USING gist (cityid);
CREATE INDEX ua_gridded_roads_cellid_idx ON ua_gridded_roads USING gist (cellid);
CREATE INDEX ua_gridded_roads_geom_idx ON ua_gridded_roads USING gist (geom);
CREATE INDEX ua_gridded_roads_geohash_idx ON ua_gridded_roads (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Streams
DROP TABLE IF EXISTS ua_gridded_streams CASCADE;
CREATE TABLE ua_gridded_streams (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(LineString,3035), --- geom GEOMETRY(MultiLineString,3035)

    stream_type CHARACTER VARYING(254),
    start_height NUMERIC NOT NULL DEFAULT 0.0,
    end_height NUMERIC NOT NULL DEFAULT 0.0,

    CONSTRAINT streams_id_pkey PRIMARY KEY (id),
    CONSTRAINT streams_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT streams_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)      
);

DROP INDEX IF EXISTS ua_gridded_streams_id_idx;
DROP INDEX IF EXISTS ua_gridded_streams_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_streams_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_streams_geom_idx;
DROP INDEX IF EXISTS ua_gridded_streams_geohash_idx;
CREATE INDEX ua_gridded_streams_id_idx ON ua_gridded_streams USING gist (id);
CREATE INDEX ua_gridded_streams_cityid_idx ON ua_gridded_streams USING gist (cityid);
CREATE INDEX ua_gridded_streams_cellid_idx ON ua_gridded_streams USING gist (cellid);
CREATE INDEX ua_gridded_streams_geom_idx ON ua_gridded_streams USING gist (geom);
CREATE INDEX ua_gridded_streams_geohash_idx ON ua_gridded_streams (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Trees
DROP TABLE IF EXISTS ua_gridded_trees CASCADE;
CREATE TABLE ua_gridded_trees (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.13,
    emissivity REAL NOT NULL DEFAULT 0.97,
    transmissivity REAL NOT NULL DEFAULT 0.25,
    vegetation_shadow REAL NOT NULL DEFAULT 0.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.05,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_green_fraction REAL NOT NULL DEFAULT 0.37,

    CONSTRAINT ua_gridded_trees_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_trees_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_trees_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)      
);

DROP INDEX IF EXISTS ua_gridded_trees_id_idx;
DROP INDEX IF EXISTS ua_gridded_trees_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_trees_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_trees_geom_idx;
DROP INDEX IF EXISTS ua_gridded_trees_geohash_idx;
CREATE INDEX ua_gridded_trees_id_idx ON ua_gridded_trees USING gist (id);
CREATE INDEX ua_gridded_trees_cityid_idx ON ua_gridded_trees USING gist (cityid);
CREATE INDEX ua_gridded_trees_cellid_idx ON ua_gridded_trees USING gist (cellid);
CREATE INDEX ua_gridded_trees_geom_idx ON ua_gridded_trees USING gist (geom);
CREATE INDEX ua_gridded_trees_geohash_idx ON ua_gridded_trees (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Vegetation
DROP TABLE IF EXISTS ua_gridded_vegetation CASCADE;
CREATE TABLE ua_gridded_vegetation (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.21,
    emissivity REAL NOT NULL DEFAULT 0.96,
    transmissivity REAL NOT NULL DEFAULT 0.30,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.18,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT ua_gridded_vegetation_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_vegetation_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_vegetation_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)      
);

DROP INDEX IF EXISTS ua_gridded_vegetation_id_idx;
DROP INDEX IF EXISTS ua_gridded_vegetation_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_vegetation_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_vegetation_geom_idx;
DROP INDEX IF EXISTS ua_gridded_vegetation_geohash_idx;
CREATE INDEX ua_gridded_vegetation_id_idx ON ua_gridded_vegetation USING gist (id);
CREATE INDEX ua_gridded_vegetation_cityid_idx ON ua_gridded_vegetation USING gist (cityid);
CREATE INDEX ua_gridded_vegetation_cellid_idx ON ua_gridded_vegetation USING gist (cellid);
CREATE INDEX ua_gridded_vegetation_geom_idx ON ua_gridded_vegetation USING gist (geom);
CREATE INDEX ua_gridded_vegetation_geohash_idx ON ua_gridded_vegetation (ST_GeoHash(ST_Transform(geom,4326)));

--- TABLE: Water
DROP TABLE IF EXISTS ua_gridded_water CASCADE;
CREATE TABLE ua_gridded_water (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.07,
    emissivity REAL NOT NULL DEFAULT 0.96,
    transmissivity REAL NOT NULL DEFAULT 0.5,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    runoff_coefficient REAL NOT NULL DEFAULT 0.1,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT ua_gridded_water_id_pkey PRIMARY KEY (id),
    CONSTRAINT ua_gridded_water_cellid_fkey FOREIGN KEY (cellid) REFERENCES laea_etrs_500m (fid),
    CONSTRAINT ua_gridded_water_cityid_fkey FOREIGN KEY (cityid) REFERENCES city (id)         
);

DROP INDEX IF EXISTS ua_gridded_water_id_idx;
DROP INDEX IF EXISTS ua_gridded_water_cityid_idx;
DROP INDEX IF EXISTS ua_gridded_water_cellid_idx;
DROP INDEX IF EXISTS ua_gridded_water_geom_idx;
DROP INDEX IF EXISTS ua_gridded_water_geohash_idx;
CREATE INDEX ua_gridded_water_id_idx ON ua_gridded_water USING gist (id);
CREATE INDEX ua_gridded_water_cityid_idx ON ua_gridded_water USING gist (cityid);
CREATE INDEX ua_gridded_water_cellid_idx ON ua_gridded_water USING gist (cellid);
CREATE INDEX ua_gridded_water_geom_idx ON ua_gridded_water USING gist (geom);
CREATE INDEX ua_gridded_water_geohash_idx ON ua_gridded_water (ST_GeoHash(ST_Transform(geom,4326)));


--- TABLE: Parameters
DROP TABLE IF EXISTS parameter CASCADE;
CREATE TABLE parameter (
    id SERIAL NOT NULL,
    "name" CHARACTER VARYING NOT NULL,
    "table" CHARACTER VARYING NOT NULL,
    "value" NUMERIC NOT NULL,

    CONSTRAINT parameter_name_table_pkey PRIMARY KEY ("name", "table")
);

DROP INDEX IF EXISTS parameter_name_table_idx;
CREATE INDEX parameter_name_table_idx ON parameter USING gist ("name", "table");

INSERT INTO parameter ("name", "table", "value")
       VALUES
        ('albedo', 'water', 0.07),
        ('albedo', 'roads', 0.1),
        ('albedo', 'railways', 0.2),
        ('albedo', 'trees', 0.13),
        ('albedo', 'vegetation', 0.21),
        ('albedo', 'agricultural_areas', 0.11),
        ('albedo', 'built_up', 0.2),
        ('albedo', 'built_open_spaces', 0.45),
        ('albedo', 'dense_urban_fabric', 0.065),
        ('albedo', 'medium_urban_fabric', 0.11),
        ('albedo', 'low_urban_fabric', 0.15),
        ('albedo', 'public_military_industrial', 0.13),
        ('context', 'dense_urban_fabric', 1),
        ('context', 'medium_urban_fabric', 0.8),
        ('context', 'low_urban_fabric', 0.5),
        ('context', 'public_military_industrial', 0.5),
        ('emissivity', 'water', 0.96),
        ('emissivity', 'roads', 0.9),
        ('emissivity', 'railways', 0.85),
        ('emissivity', 'trees', 0.97),
        ('emissivity', 'vegetation', 0.96),
        ('emissivity', 'agricultural_areas', 0.95),
        ('emissivity', 'built_up', 0.85),
        ('emissivity', 'built_open_spaces', 0.9),
        ('emissivity', 'dense_urban_fabric', 0.9),
        ('emissivity', 'medium_urban_fabric', 0.9),
        ('emissivity', 'low_urban_fabric', 0.9),
        ('emissivity', 'public_military_industrial', 0.9),
        ('fua_tunnel', 'dense_urban_fabric', 1.2),
        ('fua_tunnel', 'medium_urban_fabric', 1.1),
        ('fua_tunnel', 'low_urban_fabric', 1.0),
        ('fua_tunnel', 'public_military_industrial', 1.0),
        ('hillshade_building', 'dense_urban_fabric', 0.6),
        ('hillshade_building', 'medium_urban_fabric', 0.8),
        ('hillshade_building', 'low_urban_fabric', 0.9),
        ('hillshade_building', 'public_military_industrial', 0.9),
        ('runoff', 'water', 0.1),
        ('runoff', 'roads', 0.9),
        ('runoff', 'railways', 0.2),
        ('runoff', 'trees', 0.05),
        ('runoff', 'vegetation', 0.18),
        ('runoff', 'agricultural_areas', 0.1),
        ('runoff', 'built_up', 0.9),
        ('runoff', 'built_open_spaces', 0.75),
        ('runoff', 'dense_urban_fabric', 0.7),
        ('runoff', 'medium_urban_fabric', 0.5),
        ('runoff', 'low_urban_fabric', 0.4),
        ('runoff', 'public_military_industrial', 0.5),
        ('transmissivity', 'water', 0.5),
        ('transmissivity', 'roads', 0.15),
        ('transmissivity', 'railways', 0.15),
        ('transmissivity', 'trees', 0.25),
        ('transmissivity', 'vegetation', 0.30),
        ('transmissivity', 'agricultural_areas', 0.25),
        ('transmissivity', 'built_up', 0.01),
        ('transmissivity', 'built_open_spaces', 0.05),
        ('transmissivity', 'dense_urban_fabric', 0.01),
        ('transmissivity', 'medium_urban_fabric', 0.02),
        ('transmissivity', 'low_urban_fabric', 0.05),
        ('transmissivity', 'public_military_industrial', 0.05),
        ('vegetation_shadow', 'water', 1),
        ('vegetation_shadow', 'roads', 1),
        ('vegetation_shadow', 'railways', 1),
        ('vegetation_shadow', 'trees', 0),
        ('vegetation_shadow', 'vegetation', 1),
        ('vegetation_shadow', 'agricultural_areas', 1),
        ('vegetation_shadow', 'built_up', 1),
        ('vegetation_shadow', 'built_open_spaces', 1);


CREATE OR REPLACE FUNCTION get_parameter_value(parameter_name text, table_name text) RETURNS numeric AS $$
    SELECT p.value FROM parameter p WHERE p.name = parameter_name AND p.table = table_name;
$$ LANGUAGE SQL;


--- This function creates a new table 'new_table' taking as basis the structure of the 'source_table'. 
--- Taken from here: https://stackoverflow.com/questions/23693873/how-to-copy-structure-of-one-table-to-another-with-foreign-key-constraints-in-ps
--- Important assumption: source table foreign keys have correct names i.e. their names contain source table name (what is a typical situation).
--- Example usage: 
---     create table base_table (base_id int primary key);
---     create table source_table (id int primary key, base_id int references base_table);
---     select create_table_like('source_table', 'new_table');


CREATE OR REPLACE FUNCTION create_table_like(source_table text, new_table text)
RETURNS void LANGUAGE plpgsql
AS $$
declare
    rec record;
begin
    execute format(
        'create table %s (like %s including all)',
        new_table, source_table);
    for rec in
        select oid, conname
        from pg_constraint
        where contype = 'f' 
        and conrelid = source_table::regclass
    loop
        execute format(
            'alter table %s add constraint %s %s',
            new_table,
            replace(rec.conname, source_table, new_table),
            pg_get_constraintdef(rec.oid));
    end loop;
end $$;