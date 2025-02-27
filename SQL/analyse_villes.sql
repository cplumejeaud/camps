 update camps.camps7  c
 set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
	ville_proche_population = computed_pop_2020,
	distance_ville_proche = round(st_distance(c.point3857, st_centroid(au.wkb_geometry))/1000),
	eurostat_computed_fua_code = au.urau_code
from demographie.URAU_RG_100K_2020_3857 au, 
	(select c.unique_id, 
	min(round(st_distance(c.point3857, st_centroid(au.wkb_geometry))/1000)) as dmin
	from demographie.URAU_RG_100K_2020_3857 au, camps.camps7  c
	where point3857 is not null 
	-- and au.urau_catg = 'F' 	and distance_ville_proche is null and horsdburba is false 
	group by unique_id) as k
where 
	point3857 is not null 
	and iso3 not in ('BIH', 'MNE', 'UNK', 'SRB', 'MKD', 'ALB', 'DNK') and "ville_proche_code postal" is  null;
	 -- and au.urau_catg = 'F' and distance_ville_proche is null and horsdburba is false  
	and round(st_distance(c.point3857, st_centroid(au.wkb_geometry))/1000) = k.dmin
	and c.unique_id = k.unique_id ;
	