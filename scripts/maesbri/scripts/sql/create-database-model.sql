--- Install extension "btree_gist", otherwise there is an error when trying to create the gist indexes of the tables
CREATE EXTENSION IF NOT EXISTS btree_gist;


--- TABLE: European Reference Grid (500m)
DROP TABLE IF EXISTS public.laea_etrs_500m CASCADE;
CREATE TABLE public.laea_etrs_500m (
    fid SERIAL NOT NULL,
    cellcode CHARACTER VARYING(254) NOT NULL, -- String identifier of this cell
    eorigin INTEGER NOT NULL, -- Easting origin for this cell
    norigin INTEGER NOT NULL, -- Northin origin for this cell
    geom GEOMETRY(POLYGON,3035) NOT NULL,

	---UNIQUE (id,eorigin,norigin)
    CONSTRAINT laea_etrs_500m_fid_pkey PRIMARY KEY (fid)
); ---PARTITION BY RANGE (eorigin, norigin);

-- CREATE TABLE laea_etrs_500m_e09n09 PARTITION OF laea_etrs_500m FOR VALUES FROM (MINVALUE, MINVALUE) TO (9000, 9000);
-- CREATE TABLE laea_etrs_500m_e09n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (9000, 17000);
-- CREATE TABLE laea_etrs_500m_e09n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (9000, 26000);
-- CREATE TABLE laea_etrs_500m_e09n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (9000, 35000);
-- CREATE TABLE laea_etrs_500m_e09n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (9000, 44000);
-- CREATE TABLE laea_etrs_500m_e09n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (9000, 54000);
-- CREATE TABLE laea_etrs_500m_e17n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 9000);
-- CREATE TABLE laea_etrs_500m_e17n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 17000);
-- CREATE TABLE laea_etrs_500m_e17n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 26000);
-- CREATE TABLE laea_etrs_500m_e17n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 35000);
-- CREATE TABLE laea_etrs_500m_e17n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 44000);
-- CREATE TABLE laea_etrs_500m_e17n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (17000, 54000);
-- CREATE TABLE laea_etrs_500m_e25n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 9000);
-- CREATE TABLE laea_etrs_500m_e25n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 17000);
-- CREATE TABLE laea_etrs_500m_e25n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 26000);
-- CREATE TABLE laea_etrs_500m_e25n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 35000);
-- CREATE TABLE laea_etrs_500m_e25n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 44000);
-- CREATE TABLE laea_etrs_500m_e25n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (25000, 54000);
-- CREATE TABLE laea_etrs_500m_e33n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 9000);
-- CREATE TABLE laea_etrs_500m_e33n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 17000);
-- CREATE TABLE laea_etrs_500m_e33n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 26000);
-- CREATE TABLE laea_etrs_500m_e33n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 35000);
-- CREATE TABLE laea_etrs_500m_e33n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 44000);
-- CREATE TABLE laea_etrs_500m_e33n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (33000, 54000);
-- CREATE TABLE laea_etrs_500m_e41n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 9000);
-- CREATE TABLE laea_etrs_500m_e41n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 17000);
-- CREATE TABLE laea_etrs_500m_e41n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 26000);
-- CREATE TABLE laea_etrs_500m_e41n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 35000);
-- CREATE TABLE laea_etrs_500m_e41n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 44000);
-- CREATE TABLE laea_etrs_500m_e41n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (41000, 54000);
-- CREATE TABLE laea_etrs_500m_e49n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 9000);
-- CREATE TABLE laea_etrs_500m_e49n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 17000);
-- CREATE TABLE laea_etrs_500m_e49n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 26000);
-- CREATE TABLE laea_etrs_500m_e49n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 35000);
-- CREATE TABLE laea_etrs_500m_e49n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 44000);
-- CREATE TABLE laea_etrs_500m_e49n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (49000, 54000);
-- CREATE TABLE laea_etrs_500m_e57n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 9000);
-- CREATE TABLE laea_etrs_500m_e57n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 17000);
-- CREATE TABLE laea_etrs_500m_e57n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 26000);
-- CREATE TABLE laea_etrs_500m_e57n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 35000);
-- CREATE TABLE laea_etrs_500m_e57n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 44000);
-- CREATE TABLE laea_etrs_500m_e57n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (57000, 54000);
-- CREATE TABLE laea_etrs_500m_e66n09 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 9000);
-- CREATE TABLE laea_etrs_500m_e66n17 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 17000);
-- CREATE TABLE laea_etrs_500m_e66n26 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 26000);
-- CREATE TABLE laea_etrs_500m_e66n35 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 35000);
-- CREATE TABLE laea_etrs_500m_e66n44 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 44000);
-- CREATE TABLE laea_etrs_500m_e66n54 PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (66000, 54000);
-- CREATE TABLE laea_etrs_500m_default PARTITION OF laea_etrs_500m FOR VALUES LESS THAN (MAXVALUE, MAXVALUE);

DROP INDEX IF EXISTS laea_etrs_500m_fid_idx;
DROP INDEX IF EXISTS laea_etrs_500m_cellcode_idx;
DROP INDEX IF EXISTS laea_etrs_500m_geom_idx;
DROP INDEX IF EXISTS laea_etrs_500m_geom_geohash_idx;
DROP INDEX IF EXISTS laea_etrs_500m_eorigin_norigin_idx;
CREATE INDEX laea_etrs_500m_fid_idx ON public.laea_etrs_500m USING gist (fid);
CREATE INDEX laea_etrs_500m_cellcode_idx ON public.laea_etrs_500m USING gist (cellcode);
CREATE INDEX laea_etrs_500m_geom_idx ON public.laea_etrs_500m USING gist (geom);
CREATE INDEX laea_etrs_500m_geom_geohash_idx ON public.laea_etrs_500m (ST_GeoHash(ST_Transform(geom,4326))); --- The geohash algorithm only works on data in geographic (longitude/latitude) coordinates, so we need to transform the geometries (to EPSG:4326, which is longitude/latitude) at the same time as we hash them.
CREATE INDEX laea_etrs_500m_eorigin_norigin_idx ON public.laea_etrs_500m USING gist (eorigin,norigin);

---CLUSTER public.laea_etrs_500m USING laea_etrs_500m_geom_idx;
---CLUSTER public.laea_etrs_500m USING laea_etrs_500m_geom_geohash_idx; --- Clustering by GeoHash: https://postgis.net/workshops/postgis-intro/clusterindex.html
---CLUSTER public.laea_etrs_500m USING laea_etrs_500m_eorigin_norigin_idx;

--- TABLE: City
DROP TABLE IF EXISTS public.city CASCADE;
CREATE TABLE public.city (
    id SERIAL NOT NULL,
    name CHARACTER VARYING(32) NOT NULL,
    code CHARACTER VARYING(7) UNIQUE NOT NULL,
    country_code CHARACTER VARYING(3) NOT NULL,
    population INTEGER NOT NULL DEFAULT 0,
    boundary GEOMETRY(MULTIPOLYGON,3035) NOT NULL,
    bbox GEOMETRY(POLYGON,3035) NOT NULL,

    CONSTRAINT city_id_pkey PRIMARY KEY (id)
);

DROP INDEX IF EXISTS city_id_idx;
DROP INDEX IF EXISTS city_name_idx;
DROP INDEX IF EXISTS city_code_idx;
DROP INDEX IF EXISTS city_country_code_idx;
DROP INDEX IF EXISTS city_bbox_idx;
DROP INDEX IF EXISTS city_boundary_idx;
CREATE INDEX city_id_idx ON public.city USING gist (id);
CREATE INDEX city_name_idx ON public.city USING gist (name);
CREATE INDEX city_code_idx ON public.city USING gist (code);
CREATE INDEX city_country_code_idx ON public.city USING gist (country_code);
CREATE INDEX city_bbox_idx ON public.city USING gist (bbox);
CREATE INDEX city_boundary_idx ON public.city USING gist (boundary);

--- TABLE: Area Land Use Grid
DROP TABLE IF EXISTS public.land_use_area;
CREATE TABLE public.land_use_area (
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

    CONSTRAINT land_use_area_id_pkey PRIMARY KEY (id),
    CONSTRAINT land_use_area_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT land_use_area_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS land_use_area_id_idx;
DROP INDEX IF EXISTS land_use_area_cellid_idx;
DROP INDEX IF EXISTS land_use_area_cityid_idx;
CREATE INDEX land_use_area_id_idx ON public.land_use_area USING gist (id);
CREATE INDEX land_use_area_cellid_idx ON public.land_use_area USING gist (cellid);
CREATE INDEX land_use_area_cityid_idx ON public.land_use_area USING gist (cityid);

---CLUSTER public.land_use_area USING land_use_area_id_idx;

--- TABLE: Agricultural Areas
DROP TABLE IF EXISTS public.agricultural_areas;
CREATE TABLE public.agricultural_areas (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.11,
    emissivity REAL NOT NULL DEFAULT 0.95,
    transmissivity REAL NOT NULL DEFAULT 0.25,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.1,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT agricultural_areas_id_pkey PRIMARY KEY (id),
    CONSTRAINT agricultural_areas_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT agricultural_areas_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS agricultural_areas_id_idx;
DROP INDEX IF EXISTS agricultural_areas_cityid_idx;
DROP INDEX IF EXISTS agricultural_areas_cellid_idx;
DROP INDEX IF EXISTS agricultural_areas_geom_idx;
CREATE INDEX agricultural_areas_id_idx ON public.agricultural_areas USING gist (id);
CREATE INDEX agricultural_areas_cityid_idx ON public.agricultural_areas USING gist (cityid);
CREATE INDEX agricultural_areas_cellid_idx ON public.agricultural_areas USING gist (cellid);
CREATE INDEX agricultural_areas_geom_idx ON public.agricultural_areas USING gist (geom);

--- TABLE: Basins
DROP TABLE IF EXISTS public.basins;
CREATE TABLE public.basins (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    CONSTRAINT basins_id_pkey PRIMARY KEY (id),
    CONSTRAINT basins_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT basins_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS basins_id_idx;
DROP INDEX IF EXISTS basins_cityid_idx;
DROP INDEX IF EXISTS basins_cellid_idx;
DROP INDEX IF EXISTS basins_geom_idx;
CREATE INDEX basins_id_idx ON public.basins USING gist (id);
CREATE INDEX basins_cityid_idx ON public.basins USING gist (cityid);
CREATE INDEX basins_cellid_idx ON public.basins USING gist (cellid);
CREATE INDEX basins_geom_idx ON public.basins USING gist (geom);

--- TABLE: Built Open Spaces
DROP TABLE IF EXISTS public.built_open_spaces;
CREATE TABLE public.built_open_spaces (
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
    run_off_coefficient REAL NOT NULL DEFAULT 0.75,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_building REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT built_open_spaces_id_pkey PRIMARY KEY (id),
    CONSTRAINT built_open_spaces_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT built_open_spaces_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS built_open_spaces_id_idx;
DROP INDEX IF EXISTS built_open_spaces_cityid_idx;
DROP INDEX IF EXISTS built_open_spaces_cellid_idx;
DROP INDEX IF EXISTS built_open_spaces_geom_idx;
CREATE INDEX built_open_spaces_id_idx ON public.built_open_spaces USING gist (id);
CREATE INDEX built_open_spaces_cityid_idx ON public.built_open_spaces USING gist (cityid);
CREATE INDEX built_open_spaces_cellid_idx ON public.built_open_spaces USING gist (cellid);
CREATE INDEX built_open_spaces_geom_idx ON public.built_open_spaces USING gist (geom);

--- TABLE: Built-Up
DROP TABLE IF EXISTS public.built_up;
CREATE TABLE public.built_up (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),    
    
    albedo REAL NOT NULL DEFAULT 0.2,
    emissivity REAL NOT NULL DEFAULT 0.85,
    transmissivity REAL NOT NULL DEFAULT 0.01,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.9,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT built_up_id_pkey PRIMARY KEY (id),
    CONSTRAINT built_up_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT built_up_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)    
);

DROP INDEX IF EXISTS built_up_id_idx;
DROP INDEX IF EXISTS built_up_cityid_idx;
DROP INDEX IF EXISTS built_up_cellid_idx;
DROP INDEX IF EXISTS built_up_geom_idx;
CREATE INDEX built_up_id_idx ON public.built_up USING gist (id);
CREATE INDEX built_up_cityid_idx ON public.built_up USING gist (cityid);
CREATE INDEX built_up_cellid_idx ON public.built_up USING gist (cellid);
CREATE INDEX built_up_geom_idx ON public.built_up USING gist (geom);

--- TABLE: Dense Urban Fabric
DROP TABLE IF EXISTS public.dense_urban_fabric;
CREATE TABLE public.dense_urban_fabric (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.065,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.4,
    run_off_coefficient REAL NOT NULL DEFAULT 0.7,
    context REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT dense_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT dense_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT dense_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS dense_urban_fabric_id_idx;
DROP INDEX IF EXISTS dense_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS dense_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS dense_urban_fabric_geom_idx;
CREATE INDEX dense_urban_fabric_id_idx ON public.dense_urban_fabric USING gist (id);
CREATE INDEX dense_urban_fabric_cityid_idx ON public.dense_urban_fabric USING gist (cityid);
CREATE INDEX dense_urban_fabric_cellid_idx ON public.dense_urban_fabric USING gist (cellid);
CREATE INDEX dense_urban_fabric_geom_idx ON public.dense_urban_fabric USING gist (geom);

--- TABLE: Low Urban Fabric
DROP TABLE IF EXISTS public.low_urban_fabric;
CREATE TABLE public.low_urban_fabric (
    id SERIAL NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,

    albedo REAL NOT NULL DEFAULT 0.15,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.4,
    context REAL NOT NULL DEFAULT 0.5,

    CONSTRAINT low_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT low_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT low_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS low_urban_fabric_id_idx;
DROP INDEX IF EXISTS low_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS low_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS low_urban_fabric_geom_idx;
CREATE INDEX low_urban_fabric_id_idx ON public.low_urban_fabric USING gist (id);
CREATE INDEX low_urban_fabric_cityid_idx ON public.low_urban_fabric USING gist (cityid);
CREATE INDEX low_urban_fabric_cellid_idx ON public.low_urban_fabric USING gist (cellid);
CREATE INDEX low_urban_fabric_geom_idx ON public.low_urban_fabric USING gist (geom);

--- TABLE: Medium Urban Fabric
DROP TABLE IF EXISTS public.medium_urban_fabric;
CREATE TABLE public.medium_urban_fabric (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.11,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.2,
    run_off_coefficient REAL NOT NULL DEFAULT 0.5,
    context REAL NOT NULL DEFAULT 0.8,

    CONSTRAINT medium_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT medium_urban_fabric_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT medium_urban_fabric_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)    
);

DROP INDEX IF EXISTS medium_urban_fabric_id_idx;
DROP INDEX IF EXISTS medium_urban_fabric_cityid_idx;
DROP INDEX IF EXISTS medium_urban_fabric_cellid_idx;
DROP INDEX IF EXISTS medium_urban_fabric_geom_idx;
CREATE INDEX medium_urban_fabric_id_idx ON public.medium_urban_fabric USING gist (id);
CREATE INDEX medium_urban_fabric_cityid_idx ON public.medium_urban_fabric USING gist (cityid);
CREATE INDEX medium_urban_fabric_cellid_idx ON public.medium_urban_fabric USING gist (cellid);
CREATE INDEX medium_urban_fabric_geom_idx ON public.medium_urban_fabric USING gist (geom);

--- TABLE: Public, Military and Industrial
DROP TABLE IF EXISTS public.public_military_industrial;
CREATE TABLE public.public_military_industrial (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.13,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.5,
    context REAL NOT NULL DEFAULT 0.5,

    CONSTRAINT public_military_industrial_id_pkey PRIMARY KEY (id),
    CONSTRAINT public_military_industrial_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT public_military_industrial_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)        
);

DROP INDEX IF EXISTS public_military_industrial_id_idx;
DROP INDEX IF EXISTS public_military_industrial_cityid_idx;
DROP INDEX IF EXISTS public_military_industrial_cellid_idx;
DROP INDEX IF EXISTS public_military_industrial_geom_idx;
CREATE INDEX public_military_industrial_id_idx ON public.public_military_industrial USING gist (id);
CREATE INDEX public_military_industrial_cityid_idx ON public.public_military_industrial USING gist (cityid);
CREATE INDEX public_military_industrial_cellid_idx ON public.public_military_industrial USING gist (cellid);
CREATE INDEX public_military_industrial_geom_idx ON public.public_military_industrial USING gist (geom);

--- TABLE: Railways
DROP TABLE IF EXISTS public.railways;
CREATE TABLE public.railways (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.2,
    emissivity REAL NOT NULL DEFAULT 0.85,
    transmissivity REAL NOT NULL DEFAULT 0.15,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.2,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT railways_id_pkey PRIMARY KEY (id),
    CONSTRAINT railways_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT railways_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)       
);

DROP INDEX IF EXISTS railways_id_idx;
DROP INDEX IF EXISTS railways_cityid_idx;
DROP INDEX IF EXISTS railways_cellid_idx;
DROP INDEX IF EXISTS railways_geom_idx;
CREATE INDEX railways_id_idx ON public.railways USING gist (id);
CREATE INDEX railways_cityid_idx ON public.railways USING gist (cityid);
CREATE INDEX railways_cellid_idx ON public.railways USING gist (cellid);
CREATE INDEX railways_geom_idx ON public.railways USING gist (geom);

--- TABLE: Roads
DROP TABLE IF EXISTS public.roads;
CREATE TABLE public.roads (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.1,
    emissivity REAL NOT NULL DEFAULT 0.9,
    transmissivity REAL NOT NULL DEFAULT 0.15,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.9,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_building REAL NOT NULL DEFAULT 1.0,

    CONSTRAINT roads_id_pkey PRIMARY KEY (id),
    CONSTRAINT roads_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT roads_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS roads_id_idx;
DROP INDEX IF EXISTS roads_cityid_idx;
DROP INDEX IF EXISTS roads_cellid_idx;
DROP INDEX IF EXISTS roads_geom_idx;
CREATE INDEX roads_id_idx ON public.roads USING gist (id);
CREATE INDEX roads_cityid_idx ON public.roads USING gist (cityid);
CREATE INDEX roads_cellid_idx ON public.roads USING gist (cellid);
CREATE INDEX roads_geom_idx ON public.roads USING gist (geom);

--- TABLE: Streams
DROP TABLE IF EXISTS public.streams;
CREATE TABLE public.streams (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(LineString,3035), --- geom GEOMETRY(MultiLineString,3035)

    stream_type CHARACTER VARYING(254),
    start_height NUMERIC NOT NULL DEFAULT 0.0,
    end_height NUMERIC NOT NULL DEFAULT 0.0,

    CONSTRAINT streams_id_pkey PRIMARY KEY (id),
    CONSTRAINT streams_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT streams_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS streams_id_idx;
DROP INDEX IF EXISTS streams_cityid_idx;
DROP INDEX IF EXISTS streams_cellid_idx;
DROP INDEX IF EXISTS streams_geom_idx;
CREATE INDEX streams_id_idx ON public.streams USING gist (id);
CREATE INDEX streams_cityid_idx ON public.streams USING gist (cityid);
CREATE INDEX streams_cellid_idx ON public.streams USING gist (cellid);
CREATE INDEX streams_geom_idx ON public.streams USING gist (geom);

--- TABLE: Trees
DROP TABLE IF EXISTS public.trees;
CREATE TABLE public.trees (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.13,
    emissivity REAL NOT NULL DEFAULT 0.97,
    transmissivity REAL NOT NULL DEFAULT 0.25,
    vegetation_shadow REAL NOT NULL DEFAULT 0.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.05,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,
    hillshade_green_fraction REAL NOT NULL DEFAULT 0.37,

    CONSTRAINT trees_pkey PRIMARY KEY (id),
    CONSTRAINT trees_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT trees_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS trees_id_idx;
DROP INDEX IF EXISTS trees_cityid_idx;
DROP INDEX IF EXISTS trees_cellid_idx;
DROP INDEX IF EXISTS trees_geom_idx;
CREATE INDEX trees_id_idx ON public.trees USING gist (id);
CREATE INDEX trees_cityid_idx ON public.trees USING gist (cityid);
CREATE INDEX trees_cellid_idx ON public.trees USING gist (cellid);
CREATE INDEX trees_geom_idx ON public.trees USING gist (geom);

--- TABLE: Vegetation
DROP TABLE IF EXISTS public.vegetation;
CREATE TABLE public.vegetation (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.21,
    emissivity REAL NOT NULL DEFAULT 0.96,
    transmissivity REAL NOT NULL DEFAULT 0.30,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.18,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT vegetation_id_pkey PRIMARY KEY (id),
    CONSTRAINT vegetation_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT vegetation_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS vegetation_id_idx;
DROP INDEX IF EXISTS vegetation_cityid_idx;
DROP INDEX IF EXISTS vegetation_cellid_idx;
DROP INDEX IF EXISTS vegetation_geom_idx;
CREATE INDEX vegetation_id_idx ON public.vegetation USING gist (id);
CREATE INDEX vegetation_cityid_idx ON public.vegetation USING gist (cityid);
CREATE INDEX vegetation_cellid_idx ON public.vegetation USING gist (cellid);
CREATE INDEX vegetation_geom_idx ON public.vegetation USING gist (geom);

--- TABLE: Water
DROP TABLE IF EXISTS public.water;
CREATE TABLE public.water (
    id SERIAL NOT NULL,
    cityid BIGINT NOT NULL,
    cellid BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL NOT NULL DEFAULT 0.07,
    emissivity REAL NOT NULL DEFAULT 0.96,
    transmissivity REAL NOT NULL DEFAULT 0.5,
    vegetation_shadow REAL NOT NULL DEFAULT 1.0,
    run_off_coefficient REAL NOT NULL DEFAULT 0.1,
    fua_tunnel REAL NOT NULL DEFAULT 1.0,
    building_shadow SMALLINT NOT NULL DEFAULT 1,

    CONSTRAINT water_id_pkey PRIMARY KEY (id),
    CONSTRAINT water_cellid_fkey FOREIGN KEY (cellid) REFERENCES public.laea_etrs_500m (fid),
    CONSTRAINT water_cityid_fkey FOREIGN KEY (cityid) REFERENCES public.city (id)         
);

DROP INDEX IF EXISTS water_id_idx;
DROP INDEX IF EXISTS water_cityid_idx;
DROP INDEX IF EXISTS water_cellid_idx;
DROP INDEX IF EXISTS water_geom_idx;
CREATE INDEX water_id_idx ON public.water USING gist (id);
CREATE INDEX water_cityid_idx ON public.water USING gist (cityid);
CREATE INDEX water_cellid_idx ON public.water USING gist (cellid);
CREATE INDEX water_geom_idx ON public.water USING gist (geom);


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