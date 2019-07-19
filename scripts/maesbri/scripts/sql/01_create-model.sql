CREATE EXTENSION IF NOT EXISTS btree_gist;


--- TABLE: European Reference Grid (500m)
DROP TABLE IF EXISTS public.laea_etrs_500m CASCADE;
CREATE TABLE public.laea_etrs_500m (
    id SERIAL NOT NULL,
    id_string CHARACTER VARYING(254) NOT NULL,
    geom GEOMETRY(POLYGON,3035) NOT NULL,

    CONSTRAINT laea_etrs_500m_id_pkey PRIMARY KEY (id)
);

DROP INDEX IF EXISTS laea_etrs_500m_id_idx;
DROP INDEX IF EXISTS laea_etrs_500m_id_string_idx;
DROP INDEX IF EXISTS laea_etrs_500m_geom_idx;
CREATE INDEX laea_etrs_500m_id_idx ON public.laea_etrs_500m USING gist (id);
CREATE INDEX laea_etrs_500m_id_string_idx ON public.laea_etrs_500m USING gist (id_string);
CREATE INDEX laea_etrs_500m_geom_idx ON public.laea_etrs_500m USING gist (geom);

CLUSTER laea_etrs_500m_geom_idx ON public.laea_etrs_500m;

--- TABLE: City
DROP TABLE IF EXISTS public.city CASCADE;
CREATE TABLE public.city (
    id SERIAL NOT NULL,
    name CHARACTER VARYING(32) NOT NULL,
    code CHARACTER VARYING(7) NOT NULL, 
    bbox GEOMETRY(POLYGON,3035) NOT NULL,

    heat_wave BOOLEAN DEFAULT FALSE,
    pluvial_flood BOOLEAN DEFAULT FALSE,
        
    CONSTRAINT city_id_pkey PRIMARY KEY (id)
);

DROP INDEX IF EXISTS city_id_idx;
DROP INDEX IF EXISTS city_name_idx;
DROP INDEX IF EXISTS city_code_idx;
DROP INDEX IF EXISTS city_bbox_idx;
CREATE INDEX city_id_idx ON public.city USING gist (id);
CREATE INDEX city_name_idx ON public.city USING gist (name);
CREATE INDEX city_code_idx ON public.city USING gist (code);
CREATE INDEX city_bbox_idx ON public.city USING gist (bbox);


--- TABLE: Area Land Use Grid
DROP TABLE IF EXISTS public.land_use_area;
CREATE TABLE public.land_use_area (
    id SERIAL NOT NULL,
    grid_id BIGINT NOT NULL,
    city_id BIGINT NOT NULL,
    
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
    CONSTRAINT land_use_area_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT land_use_area_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS land_use_area_id_idx;
DROP INDEX IF EXISTS land_use_area_grid_id_idx;
DROP INDEX IF EXISTS land_use_area_city_id_idx;
CREATE INDEX land_use_area_id_idx ON public.land_use_area USING gist (id);
CREATE INDEX land_use_area_grid_id_idx ON public.land_use_area USING gist (grid_id);
CREATE INDEX land_use_area_city_id_idx ON public.land_use_area USING gist (city_id);

CLUSTER land_use_area_id_idx ON public.land_use_area;

--- TABLE: Agricultural Areas
DROP TABLE IF EXISTS public.agricultural_areas;
CREATE TABLE public.agricultural_areas (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.11,
    emissivity REAL DEFAULT 0.95,
    transmissivity REAL DEFAULT 0.25,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.1,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,

    CONSTRAINT agricultural_areas_id_pkey PRIMARY KEY (id),
    CONSTRAINT agricultural_areas_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT agricultural_areas_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS agricultural_areas_id_idx;
DROP INDEX IF EXISTS agricultural_areas_city_id_idx;
DROP INDEX IF EXISTS agricultural_areas_grid_id_idx;
DROP INDEX IF EXISTS agricultural_areas_geom_idx;
CREATE INDEX agricultural_areas_id_idx ON public.agricultural_areas USING gist (id);
CREATE INDEX agricultural_areas_city_id_idx ON public.agricultural_areas USING gist (city_id);
CREATE INDEX agricultural_areas_grid_id_idx ON public.agricultural_areas USING gist (grid_id);
CREATE INDEX agricultural_areas_geom_idx ON public.agricultural_areas USING gist (geom);

--- TABLE: Basins
DROP TABLE IF EXISTS public.basins;
CREATE TABLE public.basins (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    CONSTRAINT basins_id_pkey PRIMARY KEY (id),
    CONSTRAINT basins_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT basins_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS basins_id_idx;
DROP INDEX IF EXISTS basins_city_id_idx;
DROP INDEX IF EXISTS basins_grid_id_idx;
DROP INDEX IF EXISTS basins_geom_idx;
CREATE INDEX basins_id_idx ON public.basins USING gist (id);
CREATE INDEX basins_city_id_idx ON public.basins USING gist (city_id);
CREATE INDEX basins_grid_id_idx ON public.basins USING gist (grid_id);
CREATE INDEX basins_geom_idx ON public.basins USING gist (geom);

--- TABLE: Built Open Spaces
DROP TABLE IF EXISTS public.built_open_spaces;
CREATE TABLE public.built_open_spaces (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    area REAL,
    perimeter REAL,
    albedo REAL DEFAULT 0.45,
    emissivity REAL DEFAULT 0.9,
    transmissivity REAL DEFAULT 0.05,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.75,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,
    hillshade_building REAL DEFAULT 1.0,

    CONSTRAINT built_open_spaces_id_pkey PRIMARY KEY (id),
    CONSTRAINT built_open_spaces_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT built_open_spaces_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS built_open_spaces_id_idx;
DROP INDEX IF EXISTS built_open_spaces_city_id_idx;
DROP INDEX IF EXISTS built_open_spaces_grid_id_idx;
DROP INDEX IF EXISTS built_open_spaces_geom_idx;
CREATE INDEX built_open_spaces_id_idx ON public.built_open_spaces USING gist (id);
CREATE INDEX built_open_spaces_city_id_idx ON public.built_open_spaces USING gist (city_id);
CREATE INDEX built_open_spaces_grid_id_idx ON public.built_open_spaces USING gist (grid_id);
CREATE INDEX built_open_spaces_geom_idx ON public.built_open_spaces USING gist (geom);

--- TABLE: Built-Up
DROP TABLE IF EXISTS public.built_up;
CREATE TABLE public.built_up (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),    
    
    albedo REAL DEFAULT 0.2,
    emissivity REAL DEFAULT 0.85,
    transmissivity REAL DEFAULT 0.01,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.9,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,

    CONSTRAINT built_up_id_pkey PRIMARY KEY (id),
    CONSTRAINT built_up_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT built_up_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)    
);

DROP INDEX IF EXISTS built_up_id_idx;
DROP INDEX IF EXISTS built_up_city_id_idx;
DROP INDEX IF EXISTS built_up_grid_id_idx;
DROP INDEX IF EXISTS built_up_geom_idx;
CREATE INDEX built_up_id_idx ON public.built_up USING gist (id);
CREATE INDEX built_up_city_id_idx ON public.built_up USING gist (city_id);
CREATE INDEX built_up_grid_id_idx ON public.built_up USING gist (grid_id);
CREATE INDEX built_up_geom_idx ON public.built_up USING gist (geom);

--- TABLE: Dense Urban Fabric
DROP TABLE IF EXISTS public.dense_urban_fabric;
CREATE TABLE public.dense_urban_fabric (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.065,
    emissivity REAL DEFAULT 0.9,
    transmissivity REAL DEFAULT 1.4,
    run_off_coefficient REAL DEFAULT 0.7,
    context REAL DEFAULT 1.0,

    CONSTRAINT dense_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT dense_urban_fabric_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT dense_urban_fabric_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS dense_urban_fabric_id_idx;
DROP INDEX IF EXISTS dense_urban_fabric_city_id_idx;
DROP INDEX IF EXISTS dense_urban_fabric_grid_id_idx;
DROP INDEX IF EXISTS dense_urban_fabric_geom_idx;
CREATE INDEX dense_urban_fabric_id_idx ON public.dense_urban_fabric USING gist (id);
CREATE INDEX dense_urban_fabric_city_id_idx ON public.dense_urban_fabric USING gist (city_id);
CREATE INDEX dense_urban_fabric_grid_id_idx ON public.dense_urban_fabric USING gist (grid_id);
CREATE INDEX dense_urban_fabric_geom_idx ON public.dense_urban_fabric USING gist (geom);

--- TABLE: Low Urban Fabric
DROP TABLE IF EXISTS public.low_urban_fabric;
CREATE TABLE public.low_urban_fabric (
    id SERIAL NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,

    albedo REAL DEFAULT 0.15,
    emissivity REAL DEFAULT 0.9,
    transmissivity REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.4,
    context REAL DEFAULT 0.5,

    CONSTRAINT low_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT low_urban_fabric_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT low_urban_fabric_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)
);

DROP INDEX IF EXISTS low_urban_fabric_id_idx;
DROP INDEX IF EXISTS low_urban_fabric_city_id_idx;
DROP INDEX IF EXISTS low_urban_fabric_grid_id_idx;
DROP INDEX IF EXISTS low_urban_fabric_geom_idx;
CREATE INDEX low_urban_fabric_id_idx ON public.low_urban_fabric USING gist (id);
CREATE INDEX low_urban_fabric_city_id_idx ON public.low_urban_fabric USING gist (city_id);
CREATE INDEX low_urban_fabric_grid_id_idx ON public.low_urban_fabric USING gist (grid_id);
CREATE INDEX low_urban_fabric_geom_idx ON public.low_urban_fabric USING gist (geom);

--- TABLE: Medium Urban Fabric
DROP TABLE IF EXISTS public.medium_urban_fabric;
CREATE TABLE public.medium_urban_fabric (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.11,
    emissivity REAL DEFAULT 0.9,
    transmissivity REAL DEFAULT 1.2,
    run_off_coefficient REAL DEFAULT 0.5,
    context REAL DEFAULT 0.8,

    CONSTRAINT medium_urban_fabric_id_pkey PRIMARY KEY (id),
    CONSTRAINT medium_urban_fabric_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT medium_urban_fabric_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)    
);

DROP INDEX IF EXISTS medium_urban_fabric_id_idx;
DROP INDEX IF EXISTS medium_urban_fabric_city_id_idx;
DROP INDEX IF EXISTS medium_urban_fabric_grid_id_idx;
DROP INDEX IF EXISTS medium_urban_fabric_geom_idx;
CREATE INDEX medium_urban_fabric_id_idx ON public.medium_urban_fabric USING gist (id);
CREATE INDEX medium_urban_fabric_city_id_idx ON public.medium_urban_fabric USING gist (city_id);
CREATE INDEX medium_urban_fabric_grid_id_idx ON public.medium_urban_fabric USING gist (grid_id);
CREATE INDEX medium_urban_fabric_geom_idx ON public.medium_urban_fabric USING gist (geom);

--- TABLE: Public, Military and Industrial
DROP TABLE IF EXISTS public.public_military_industrial;
CREATE TABLE public.public_military_industrial (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo real DEFAULT 0.13,
    emissivity real DEFAULT 0.9,
    transmissivity real DEFAULT 1.0,
    run_off_coefficient real DEFAULT 0.5,
    context real DEFAULT 0.5,

    CONSTRAINT public_military_industrial_id_pkey PRIMARY KEY (id),
    CONSTRAINT public_military_industrial_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT public_military_industrial_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)        
);

DROP INDEX IF EXISTS public_military_industrial_id_idx;
DROP INDEX IF EXISTS public_military_industrial_city_id_idx;
DROP INDEX IF EXISTS public_military_industrial_grid_id_idx;
DROP INDEX IF EXISTS public_military_industrial_geom_idx;
CREATE INDEX public_military_industrial_id_idx ON public.public_military_industrial USING gist (id);
CREATE INDEX public_military_industrial_city_id_idx ON public.public_military_industrial USING gist (city_id);
CREATE INDEX public_military_industrial_grid_id_idx ON public.public_military_industrial USING gist (grid_id);
CREATE INDEX public_military_industrial_geom_idx ON public.public_military_industrial USING gist (geom);

--- TABLE: Railways
DROP TABLE IF EXISTS public.railways;
CREATE TABLE public.railways (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.2,
    emissivity REAL DEFAULT 0.85,
    transmissivity REAL DEFAULT 0.15,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.2,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,

    CONSTRAINT railways_id_pkey PRIMARY KEY (id),
    CONSTRAINT railways_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT railways_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)       
);

DROP INDEX IF EXISTS railways_id_idx;
DROP INDEX IF EXISTS railways_city_id_idx;
DROP INDEX IF EXISTS railways_grid_id_idx;
DROP INDEX IF EXISTS railways_geom_idx;
CREATE INDEX railways_id_idx ON public.railways USING gist (id);
CREATE INDEX railways_city_id_idx ON public.railways USING gist (city_id);
CREATE INDEX railways_grid_id_idx ON public.railways USING gist (grid_id);
CREATE INDEX railways_geom_idx ON public.railways USING gist (geom);

--- TABLE: Roads
DROP TABLE IF EXISTS public.roads;
CREATE TABLE public.roads (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.1,
    emissivity REAL DEFAULT 0.9,
    transmissivity REAL DEFAULT 0.15,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.9,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,
    hillshade_building REAL DEFAULT 1.0,

    CONSTRAINT roads_id_pkey PRIMARY KEY (id),
    CONSTRAINT roads_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT roads_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS roads_id_idx;
DROP INDEX IF EXISTS roads_city_id_idx;
DROP INDEX IF EXISTS roads_grid_id_idx;
DROP INDEX IF EXISTS roads_geom_idx;
CREATE INDEX roads_id_idx ON public.roads USING gist (id);
CREATE INDEX roads_city_id_idx ON public.roads USING gist (city_id);
CREATE INDEX roads_grid_id_idx ON public.roads USING gist (grid_id);
CREATE INDEX roads_geom_idx ON public.roads USING gist (geom);

--- TABLE: Streams
DROP TABLE IF EXISTS public.streams;
CREATE TABLE public.streams (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(LineString,3035), --- geom GEOMETRY(MultiLineString,3035)

    stream_type CHARACTER VARYING(254),
    start_height NUMERIC DEFAULT 0.0,
    end_height NUMERIC DEFAULT 0.0,

    CONSTRAINT streams_id_pkey PRIMARY KEY (id),
    CONSTRAINT streams_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT streams_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS streams_id_idx;
DROP INDEX IF EXISTS streams_city_id_idx;
DROP INDEX IF EXISTS streams_grid_id_idx;
DROP INDEX IF EXISTS streams_geom_idx;
CREATE INDEX streams_id_idx ON public.streams USING gist (id);
CREATE INDEX streams_city_id_idx ON public.streams USING gist (city_id);
CREATE INDEX streams_grid_id_idx ON public.streams USING gist (grid_id);
CREATE INDEX streams_geom_idx ON public.streams USING gist (geom);

--- TABLE: Trees
DROP TABLE IF EXISTS public.trees;
CREATE TABLE public.trees (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.13,
    emissivity REAL DEFAULT 0.97,
    transmissivity REAL DEFAULT 0.25,
    vegetation_shadow REAL DEFAULT 0.0,
    run_off_coefficient REAL DEFAULT 0.05,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,
    hillshade_green_fraction REAL DEFAULT 0.37,

    CONSTRAINT trees_pkey PRIMARY KEY (id),
    CONSTRAINT trees_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT trees_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS trees_id_idx;
DROP INDEX IF EXISTS trees_city_id_idx;
DROP INDEX IF EXISTS trees_grid_id_idx;
DROP INDEX IF EXISTS trees_geom_idx;
CREATE INDEX trees_id_idx ON public.trees USING gist (id);
CREATE INDEX trees_city_id_idx ON public.trees USING gist (city_id);
CREATE INDEX trees_grid_id_idx ON public.trees USING gist (grid_id);
CREATE INDEX trees_geom_idx ON public.trees USING gist (geom);

--- TABLE: Vegetation
DROP TABLE IF EXISTS public.vegetation;
CREATE TABLE public.vegetation (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.21,
    emissivity REAL DEFAULT 0.96,
    transmissivity REAL DEFAULT 0.30,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.18,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,

    CONSTRAINT vegetation_id_pkey PRIMARY KEY (id),
    CONSTRAINT vegetation_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT vegetation_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)      
);

DROP INDEX IF EXISTS vegetation_id_idx;
DROP INDEX IF EXISTS vegetation_city_id_idx;
DROP INDEX IF EXISTS vegetation_grid_id_idx;
DROP INDEX IF EXISTS vegetation_geom_idx;
CREATE INDEX vegetation_id_idx ON public.vegetation USING gist (id);
CREATE INDEX vegetation_city_id_idx ON public.vegetation USING gist (city_id);
CREATE INDEX vegetation_grid_id_idx ON public.vegetation USING gist (grid_id);
CREATE INDEX vegetation_geom_idx ON public.vegetation USING gist (geom);

--- TABLE: Water
DROP TABLE IF EXISTS public.water;
CREATE TABLE public.water (
    id SERIAL NOT NULL,
    city_id BIGINT NOT NULL,
    grid_id BIGINT NOT NULL,
    geom GEOMETRY(MULTIPOLYGON,3035),

    albedo REAL DEFAULT 0.07,
    emissivity REAL DEFAULT 0.96,
    transmissivity REAL DEFAULT 0.5,
    vegetation_shadow REAL DEFAULT 1.0,
    run_off_coefficient REAL DEFAULT 0.1,
    fua_tunnel REAL DEFAULT 1.0,
    building_shadow SMALLINT DEFAULT 1,

    CONSTRAINT water_id_pkey PRIMARY KEY (id),
    CONSTRAINT water_grid_id_fkey FOREIGN KEY (grid_id) REFERENCES public.laea_etrs_500m (id),
    CONSTRAINT water_city_id_fkey FOREIGN KEY (city_id) REFERENCES public.city (id)         
);

DROP INDEX IF EXISTS water_id_idx;
DROP INDEX IF EXISTS water_city_id_idx;
DROP INDEX IF EXISTS water_grid_id_idx;
DROP INDEX IF EXISTS water_geom_idx;
CREATE INDEX water_id_idx ON public.water USING gist (id);
CREATE INDEX water_city_id_idx ON public.water USING gist (city_id);
CREATE INDEX water_grid_id_idx ON public.water USING gist (grid_id);
CREATE INDEX water_geom_idx ON public.water USING gist (geom);