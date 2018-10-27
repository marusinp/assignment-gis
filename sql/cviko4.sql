SELECT * from planet_osm_polygon as a, planet_osm_polygon as b
where a.name = 'Karlova Ves' AND ST_Intersects(a.way,b.way)

select f.osm_id, f.name, f.touches
from (
    select a.*, st_touches(a.way, b.way) as touches
    from planet_osm_polygon as a,
    (
        select * from planet_osm_polygon as c
        where 1=1
            and c.name like 'Karlova Ves'
        limit 1
    ) as b
    where 1=1
        and a.name not like 'Karlova Ves'
) as f
where 1=1
    and f.touches = true;
	
select b.name from planet_osm_line as a, planet_osm_line as b
where a.name='Molecova' and ST_INTERSECTS(a.way, b.way)

