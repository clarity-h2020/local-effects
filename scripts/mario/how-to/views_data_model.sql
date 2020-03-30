CREATE OR REPLACE VIEW public.view_land_use_grid
 AS
 SELECT l.id,
    l.cell,
    l.city,
	c.name,
    l.water,
    l.roads,
    l.railways,
    l.trees,
    l.vegetation,
    l.agricultural_areas,
    l.sports,
    l.built_open_spaces,
    l.dense_urban_fabric,
    l.medium_urban_fabric,
    l.low_urban_fabric,
    l.public_military_industrial,
    l.streams,
    l.basin,
    l.mean_altitude AS altitude,
    l.built_density,
    l.basin_altitude AS minimum,
    g.geom,
    g.gridid AS cell_name
   FROM land_use_grid l,
    laea_etrs_500m g, city c
  WHERE l.cell=g.gid and l.city=c.id;
  
  
CREATE OR REPLACE VIEW public.view_mortality
 AS
 SELECT c.id,
    c.name,
    c.code,
    m.deaths,
    m.population,
    m.rate,
    c.boundary
   FROM mortality m,
    city c
  WHERE c.id = m.city
  ORDER BY c.id;