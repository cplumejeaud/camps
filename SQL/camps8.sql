---------------------------------------------
-- Script de mise à jour des infos sur les camps, version 26 février 2025 de L. Fernier (base locale camps7 du 26.02.2025)
-- Auteur : Christine PLUMEJEAUD-PERREAU, UMR 7301 MIGRINTER
-- Date de creation : 27/09/2024
-- Date de mise à jour : 26/02 (par copie de camps6.sql)
-- Base de données camps_europe sur mapuce (TGIR humanum)******
---------------------------------------------

-- camps 8

-- importée depuis Python
-- C:\Travail\MIGRINTER\Labo\Louis_Fernier\Analyse_camp_Nov2024\camps.ipynb

select  c.unique_id , c.id , c.nom 
from   camps.camps6 c 
where c.unique_id not in (select unique_id from camps.camps5) and nom is not null and nom != '';
-- 1791 dont 257 nouveaux

select count(distinct c.unique_id )
from   camps.camps6 c ;
-- 1791

-- trouver les localisations non renseignées (pas de géométrie)
select count(*) from camps.camps6 where camp_latitude is null and doublon = 'Non';
-- 16

select * from camps.camps6  where camp_latitude is null and doublon = 'Non';
select distinct doublon from camps.camps6;

select unique_id, doublon, nom, pays, camp_latitude , camp_longitude , localisation_qualite, bdd_source, sources    
from  camps.camps6 where camp_latitude is null and doublon = 'Non';
-- export des camps sans adresse

-- rajouter la colonne geom
alter table camps.camps6 add column geom geometry;

update camps.camps6 c set geom = st_setsrid(st_makepoint(camp_longitude, camp_latitude), 4326)
where camp_latitude is not null; --1765

alter table camps.camps6 drop column point3857 ;
alter table camps.camps6 drop column point3035 ;

alter table camps.camps6 add column point3857 geometry;
update camps.camps6 c set point3857 = st_setsrid(st_transform(geom, 3857), 3857);

alter table camps.camps6 add column point3035 geometry;
update camps.camps6 c set point3035 = st_setsrid(st_transform(geom, 3035), 3035);

CREATE INDEX sidx_camps6_point3035 ON camps.camps6 USING gist (point3035);
vacuum analyse;

--- 
-- CLC

select c.iso3 , c.nom,  c.clc_majoritaire_3,  clc.code_18 , substring(clc.code_18 for 2) 
from camps.camps6 c, clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035) and c.iso3 = 'FRA';

alter table camps.camps6 drop column IF exists "2024_jointure_bleu";
-- fait avec Python ensuite

alter table camps.camps6 rename column clc_majoritaire_4 to clc_majoritaire_2;
alter table camps.camps6 alter column clc_majoritaire_2 type int using clc_majoritaire_2::int;
alter table camps.camps6 alter column clc_majoritaire_3 type int using clc_majoritaire_3::int;

 
update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1 clc
where st_contains(clc.shape, c.point3035);
-- 1496

select * from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1 clc
where c.unique_id = 195 and st_intersects(clc.shape, c.point3035);

select * from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1 clc
where c.unique_id = 209 and st_contains(clc.shape, c.point3035);

select unique_id, nom, clc_majoritaire_3  from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1 clc
where c.unique_id not in (select unique_id from camps.camps5 c2) and st_contains(clc.shape, c.point3035);


select unique_id, nom, pays, localisation_qualite 
from camps.camps6 
where CLC_majoritaire_3 is null and geom is not null and pays = 'France'
order by pays;
-- 269 / 18 en France



------
-- correction après import des CLC dans les French DOM (programme python)
-- /data/clc/u2018_clc2018_v2020_20u1_fgdb/gdb/u2018_clc2018_v2020_20u1_fgdb/DATA/French_DOMs
-------
select unique_id, nom, pays, localisation_qualite , clc.* from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1_fr_glp clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4559), 4559));
-- 2 en GLP

 
update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1_fr_glp clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4559), 4559));
-- 2

select unique_id, nom, pays, localisation_qualite , clc.* from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1_fr_guf clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 2972), 2972));
-- 3 en guyanne

update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1_fr_guf clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 2972), 2972));
-- 3

select unique_id, nom, pays, localisation_qualite , clc.* from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1_fr_mtq clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4559), 4559));
-- 4 en martinique

update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1_fr_mtq clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4559), 4559));
-- 4

select unique_id, nom, pays, localisation_qualite , clc.* from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1_fr_myt clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4471), 4471));
-- 4 en mayotte

update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1_fr_myt clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 4471), 4471));
-- 4

select unique_id, nom, pays, localisation_qualite , clc.* from 
camps.camps6 c , clc.u2018_clc2018_v2020_20u1_fr_reu clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 2975), 2975));
-- 3 en réunion

update camps.camps6 c set CLC_majoritaire_3 = clc.code_18::int, CLC_majoritaire_2 = substring(clc.code_18 for 2)::int
from clc.u2018_clc2018_v2020_20u1_fr_reu clc
where CLC_majoritaire_3 is null and geom is not null and pays = 'France' 
and st_contains(clc.shape, st_setsrid(st_transform(c.geom, 2975), 2975));
-- 3


select nom, pays, localisation_qualite , distance_ville_proche 
from camps.camps6 
where distance_ville_proche is not null and geom is not null
order by pays, distance_ville_proche;


select unique_id, nom, pays, localisation_qualite, * 
from camps.camps6 
where CLC_majoritaire_3 is not null and pays = 'France' and (camp_longitude < -5 or camp_longitude > 10)
order by pays;

-- mettre à jour la distance aux CLC
-- Reprise ici le Mercredi 26/02/2025 pour calculer la distance aux CLC en mètres
-- distance_124_aeroport
update camps.camps8  c set distance_124_aeroport = k.min_d/1000
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where clc.code_18 = '124'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '124' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '124' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '124' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '124' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '124' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1791 lignes en 29 s

-- distance_13_mines_decharges_chantiers
update camps.camps8  c set distance_13_mines_decharges_chantiers = k.min_d/1000
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where clc.code_18 like '13%'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '13%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '13%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '13%'
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '13%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '13%' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1791 , 1 min 17s

--distance_123_zones_portuaires
update camps.camps8  c set distance_123_zones_portuaires = k.min_d/1000
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where clc.code_18 like '123'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '123' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '123' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '123' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '123' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '123' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1791 , 10 s

--distance_122_reseaux_routiers
update camps.camps8  c set distance_122_reseaux_routiers = k.min_d/1000
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where clc.code_18 like '122'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '122' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '122' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '122' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '122' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '122' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1791 en 50 s

-- distance_41_zones_humides_interieures

update camps.camps8  c set distance_41_zones_humides_interieures = k.min_d/1000
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where geom is not null and clc.code_18 like '41%'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '41%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '41%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '41%'
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '41%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '41%' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1781 en 9 min 25

-- distance_24_zones_agricoles_heterogenes






-- précédemment

--alter table camps.countries  add column geom3035 geometry;
--update camps.countries set geom3035 = st_setsrid(st_transform(st_setsrid(box2D(geom), 4126), 3035), 3035);
---- 258
--
--create table camps.distance_CLC_zones_agricoles_heterogenes as
--(select pays.adm0_a3 as country, c.unique_id, st_distance(c.point3035, clc.shape) as distance_clc_24
--from camps.camps5 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
--where c.geom is not null and c.iso3 = pays.adm0_a3 and  clc.code_18 like '24%' and (clc.shape && geom3035 )
--);
--
---- ajout le mardi 01/10/2024
--insert into camps.distance_CLC_zones_agricoles_heterogenes
--(select pays.adm0_a3 as country, c.unique_id, st_distance(c.point3035, clc.shape) as distance_clc_24
--from camps.camps6 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
--where  unique_id not in (select unique_id from camps.camps5 c)
--and c.geom is not null and c.iso3 = pays.adm0_a3 and  clc.code_18 like '24%' and (clc.shape && geom3035 )
--);
---- 5 min le 01.10.2024

-- ajout le mercredi 26/02/2025
insert into camps.distance_CLC_zones_agricoles_heterogenes
(select pays.adm0_a3 as country, c.unique_id, st_distance(c.point3035, clc.shape) as distance_clc_24
from camps.camps8 c, camps.countries pays, clc.u2018_clc2018_v2020_20u1 clc
where  unique_id not in (select unique_id from camps.camps6 c)
and c.geom is not null and c.iso3 = pays.adm0_a3 and  clc.code_18 like '24%' and (clc.shape && geom3035 )
);
-- 0 : pas de nouveaux camps. 
select unique_id from camps8 where (unique_id not in (select unique_id from camps.camps6 c));

update camps.camps8  c set distance_24_zones_agricoles_heterogenes = k.min_d/1000
from (
select c.unique_id, min(distance_clc_24) as min_d
from camps.distance_CLC_zones_agricoles_heterogenes c
group by c.unique_id) as k -- 49 s
where k.unique_id = c.unique_id; --516 en 40s
-- 1605
-- 1 min 25

-- recalculer sur les DOM français
update camps.camps8  c set distance_24_zones_agricoles_heterogenes = (k.min_d/1000)
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '24%' 
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '24%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '24%'
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '24%' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 like '24%' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 19 lignes en 0.183 s


-- ajout le 27/02/2025
alter table camps.camps8 add column distance_121_zi_zac float;
comment on column camps.camps8.distance_121_zi_zac is 'Distance aux zones industrielles ou commerciales et installations publiques';

select round(distance_121_zi_zac::numeric, 3) from camps.camps8 
select distance_121_zi_zac from camps.camps8 

update camps.camps8  c set distance_121_zi_zac = round(k.min_d::numeric/1000, 3)
from (
select unique_id, min(min_d) as min_d from 
(
	select c.unique_id, min(st_distance(c.point3035, clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1 clc
	where clc.code_18 = '121'
	group by c.unique_id
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_glp clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '121' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2972), 2972), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_guf clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '121' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4559), 4559), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_mtq clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '121' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 4471), 4471), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_myt clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '121' 
	group by c.unique_id
	)
	union
	(
	select c.unique_id, min(st_distance(st_setsrid(st_transform(c.geom, 2975), 2975), clc.shape)) as min_d
	from camps.camps8 c, clc.u2018_clc2018_v2020_20u1_fr_reu clc
	where pays = 'France' and (camp_longitude < -5 or camp_longitude > 10) and clc.code_18 = '121' 
	group by c.unique_id
	)
) as k1 
group by unique_id  
) as k where k.unique_id = c.unique_id;
-- 1791, 3m21s

alter table camps.camps6 rename column clc_majoritaire_4 to clc_majoritaire_2;

-- Martinique Aimé Césaire (Aéroport de)	France	quartier
select unique_id, clc_majoritaire_3 , clc_majoritaire_2 ,
distance_13_mines_decharges_chantiers , distance_123_zones_portuaires , distance_124_aeroport ,
distance_122_reseaux_routiers , distance_24_zones_agricoles_heterogenes , distance_41_zones_humides_interieures 
from camps.camps6 c where nom ='Martinique Aimé Césaire (Aéroport de)';
-- 195
-- camps6 :  195	124	12	4.0					4.0					0.0						3.0					1.0
-- camps8 :	 195	124	12	3.5649440896370437	4.297205716377485	0.0	1278.2695679474311	2.925235810864297	0.5414400652479667

select unique_id, nom, clc_majoritaire_3 , clc_majoritaire_2 ,
distance_13_mines_decharges_chantiers , distance_123_zones_portuaires , distance_124_aeroport ,
distance_122_reseaux_routiers , distance_24_zones_agricoles_heterogenes , distance_41_zones_humides_interieures 
from camps.camps8 c
where
pays = 'France' and (camp_longitude < -5 or camp_longitude > 10);

update camps.camps8 c
set distance_13_mines_decharges_chantiers = null where distance_13_mines_decharges_chantiers > 1000;
-- 21
update camps.camps8 c
set distance_123_zones_portuaires = null where distance_123_zones_portuaires > 1000;
--21
update camps.camps8 c
set distance_124_aeroport = null where distance_124_aeroport > 1000;
--21
update camps.camps8 c
set distance_122_reseaux_routiers = null where distance_122_reseaux_routiers > 1000;
-- 36
update camps.camps8 c
set distance_24_zones_agricoles_heterogenes = null where distance_24_zones_agricoles_heterogenes > 1000;
-- 5
update camps.camps8 c
set distance_41_zones_humides_interieures = null where distance_41_zones_humides_interieures > 1000;
-- 39
alter table camps.camps8 alter column distance_24_zones_agricoles_heterogenes type float using distance_24_zones_agricoles_heterogenes::float;
select unique_id, nom, distance_41_zones_humides_interieures from camps.camps8 c where distance_41_zones_humides_interieures > 1000;

select unique_id, nom, clc_majoritaire_3 , clc_majoritaire_2 ,
distance_13_mines_decharges_chantiers , distance_123_zones_portuaires , distance_124_aeroport ,
distance_122_reseaux_routiers , distance_24_zones_agricoles_heterogenes , distance_41_zones_humides_interieures 
from camps.camps8 c
where unique_id in (452, 597);
-- Canaries bien renseignées

-- fin de reprise des calculs CLC le 26/02/2025
select unique_id, c.nom_court , pays, clc_majoritaire_2 from camps8 c 
where c.clc_majoritaire_13_mixte is null and c.geom is not null 
order by pays;
----------------------------------------------------------------------------------------------------
-- demande de Louis du 1/10 : zoomer sur les CLC 11, 12, 13, 14 au niveau 3
alter table camps.camps6 add column clc_majoritaire_23_mixte int;
update camps.camps6  set clc_majoritaire_23_mixte = clc_majoritaire_2 where clc_majoritaire_2 not in (11,12,13,14);
-- 244
update camps.camps6  set clc_majoritaire_23_mixte = clc_majoritaire_3 where clc_majoritaire_2  in (11,12,13,14);
-- 1268


-- SAGEO25
-- demande de Louis et Christine du 19/12 pour article sageo : zoomer sur les CLC 11, 12, 13, 14 au niveau 3
alter table camps.camps6 add column clc_majoritaire_13_mixte int;
--select clc_majoritaire_2, substring(clc_majoritaire_2::text for 1) from camps.camps6
update camps.camps6  set clc_majoritaire_13_mixte = substring(clc_majoritaire_2::text for 1)::int where clc_majoritaire_2 not in (11,12,13,14);
-- 246
update camps.camps6  set clc_majoritaire_13_mixte = clc_majoritaire_3 where clc_majoritaire_2  in (11,12,13,14);
-- 1274
----------------------------------
-- Distance de Schengen
-- distancesc


select  distancesc from camps.camps5; 
alter table camps.camps6 add column  distanceSchengenkm float default null;
comment on column camps.camps6.distanceSchengenkm is 'Distance en km aux frontières de l''espace de Schengen sur la base du fond natural Earth 10 000eme.';
alter table camps.camps6 add column  eloignementSchengen text default null;
comment on column camps.camps6.eloignementSchengen is 'Factorielle indiquant l''éloignement par l''intérieur ou l''extérieur aux frontières de l''espace de Schengen, à plus ou moins 30 km, soit une journée de marche, sur la base du fond natural Earth 10 000eme.';

select * from demographie.ne_10m_admin_0_countries ne
where ne.Espace_Schengen is true ;

update camps.camps6  c set distanceSchengenkm = round(k.min_d/1000)
from (
	select c.unique_id, min(st_distance(c.point3857, ne.poly3857)) as min_d
	from camps.camps6 c, demographie.ne_10m_admin_0_countries ne
	where ne.Espace_Schengen is true 
	group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 1791

update camps.camps6  c set distanceSchengenkm = round(k.min_d/1000)
from (
	select c.unique_id, min(st_distance(c.point3857, st_boundary(ne.poly3857))) as min_d
	from camps.camps6 c, demographie.ne_10m_admin_0_countries ne
	where ne.Espace_Schengen is true and c.distanceSchengenkm = 0
	group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 1285 interne

select unique_id, nom, pays, distanceSchengenkm  from camps.camps6 where pays = 'France'
-- distanceSchengenkm > 30;

update camps.camps6  c set eloignementSchengen = 'loin_interne' 
where distanceSchengenkm > 30 and 
 	iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' );
-- 688

update camps.camps6  c set eloignementSchengen = 'proche_interne' 
where distanceSchengenkm <= 30 and 
 	iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' );
-- 610

update camps.camps6  c set eloignementSchengen = 'loin_externe' 
where distanceSchengenkm > 30 and 
 	iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' );
-- 436

update camps.camps6  c set eloignementSchengen = 'proche_externe' 
where distanceSchengenkm <= 30 and 
 	iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' );
-- 31



/* unique_id, nom, distancesc, distanceSchengenkm
424	Giurgiu Regional Center for Procedures and Accommodation for Asylum Seekers	335	325.0
427	Otopeni Centre for Accommodation of Foreigners Taken into Public Custody	429	430.0
520	Hatay	904	886.0
514	Istanbul (aéroport int. Ataturk)	248	249.0
542	Lutsk Temporary Holding Facility	133	134.0
544	Lviv Temporary Holding Facility	89	91.0
547	Donetsk Temporary Holding Facility	1584	1575.0
756	Ankara airport	728	727.0
538	Chernigiv Temporary Holding Facility	786	721.0
577	Cambridge. Oakington IRC	300	302.0
571	Doncaster. South Yorkshire. Lindholme IRC	564	560.0
543	Mostys'ka Temporary Holding Facility	21	20.0
553	Kyiv	707	706.0
*/
select  pays, eloignementSchengen ,  count(*), min(distance_124_aeroport) as aeroport_dmin, avg(distance_124_aeroport) as aeroport_dmoyenne, stddev(distance_124_aeroport) as aeroport_decarttype, max(distance_124_aeroport) as aeroport_dmax, max(distance_124_aeroport)-min(distance_124_aeroport) as aeroport_fourchette
from camps.camps6 
where iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC' )
group by pays, eloignementSchengen
order by pays, eloignementSchengen;


----------------------------------------------------------
-- https://ec.europa.eu/eurostat/web/gisco/geodata/statistical-units/local-administrative-units
-- D:\Data\NUTS\ref-lau-2021-01m.shp

select unique_id, nom, pays, c.distance_ville_proche, c.eurostat_computed_gisco_id , c.eurostat_computed_city_code, c.eurostat_computed_fua_code , c.eurostat_nuts_code_2016 , c.eurostat_nsi_code_2016 , c.eurostat_name_ascii_2016 , c.eurostat_pop_2019 , c.eurostat_nuts_code_2016_level3 , c.eurostat_nuts_code_2021_level3  
from camps.camps6 c 
where c.unique_id in (select unique_id from camps.camps5)
order by distance_ville_proche desc ;

-----------------------------
-- pop des villes proches 
-----------------------------
select  c.nom , c.pays ,c.unique_id , c.doublon , c.camp_adresse , c.eurostat_name_ascii_2016, c.eurostat_nuts_code_2016,
 g.nsi_code,
 g.computed_city_code,
g.computed_fua_code,
g.nuts_code,
 g.nsi_code,
 g.name_asci,
coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat"  g , camps.camps6 c 
where st_contains(g.geom, c.point3857) and c.eurostat_name_ascii_2016  is null
order by pays, nom;
--793 

update camps.camps6 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat" g 
where st_contains(g.geom, c.point3857) and c.eurostat_name_ascii_2016 is null;
-- 793

select  pays, count(*) as c from camps.camps6 
where eurostat_name_ascii_2016 is null and geom is not null
group by pays
order by c desc

/*
 * 
Libyan Arab Jamahiriya	54
Egypt	52
Turkey	46
Morocco	45
Jordan	21
Lebanon	20
Bosnia and Herzegovina	13
Israel	12
Tunisia	7
Mauritania	4
Belarus	4
Azerbaijan	2
Georgia	1
Netherlands	1
France	1
Western Sahara	1
Montenegro	1
 */

alter table camps.camps6 add column point4258 geometry;
update camps.camps6  set point4258 = st_setsrid(st_transform(geom, 4258), 4258);
CREATE INDEX sidx_camps6_point4258 ON camps.camps6 USING gist (point4258);
vacuum analyse camps.camps6;


select c.nom, g.dgurba , c.degurba 
from demographie."DGURBA_2018_01M" g, camps.camps6 c
where st_contains(g.geom, point4258) and degurba is null;
-- 794

update camps.camps6 c set degurba = g.dgurba 
from demographie."DGURBA_2018_01M" g
where st_contains(g.geom, point4258) and degurba is null;
-- 794

comment on column camps.camps6.degurba is 'Degré d''urbanisation des unités LAU : 1 -ville) - 2 (banlieue) - 3 (rural) - croisement avec la base Eurostat degurba EPSG 4258';

select unique_id, nom, pays, iso3 , c.localisation_qualite , c.eurostat_pop_2019
from camps.camps6 c
where degurba is null and geom is not null
order by pays;

select distinct pays
from camps.camps6 c
where degurba is null and geom is not null
order by pays;

alter table camps.camps6 add column horsDBURBA boolean default false;
comment on column camps.camps6.horsDBURBA is 'Vrai si en dehors de la base Eurostat degurba (limites FUA) 2018 EPSG 4258';

update camps.camps6 c set horsDBURBA = true
where degurba is null and geom is not null and pays not in ('France', 'Greece')
-- 312

update camps.camps6 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat" g 
where eurostat_name_ascii_2016 is null and st_intersects(g.geom, st_buffer(c.point3857, 1000)) 
and horsDBURBA is false;
-- traiter les cas 'France', 'Greece' qui sont des ports (bordure du shape)

update camps.camps6 c set 
eurostat_computed_gisco_id = g.nsi_code,
eurostat_computed_city_code = g.computed_city_code,
eurostat_computed_fua_code = g.computed_fua_code,
eurostat_nuts_code_2016 = g.nuts_code,
eurostat_nsi_code_2016 = g.nsi_code,
eurostat_name_ascii_2016 = g.name_asci,
eurostat_pop_2019 = coalesce(pop_2019, coalesce(pop_2018, coalesce(pop_2011, -1)))
from  demographie."GISCO_LAU_eurostat" g 
where eurostat_computed_city_code is null and st_intersects(g.geom, st_buffer(c.point3857, 1000)) 
and horsDBURBA is false;
-- 925 (OK)

select nom, pays  from camps.camps6 c 
where eurostat_name_ascii_2016 is null and geom is not null
order by pays;
-- Kareç. Centre de détention fermé	Albania
-- Vordernberg	Austria
-- Sainte-Ode - centre d'accueil	Belgium

select unique_id, nom, pays, iso3 , c.localisation_qualite , c.eurostat_pop_2019, c.degurba , horsDBURBA
from camps.camps6 c
where eurostat_pop_2019 is null and geom is not null 
-- and horsDBURBA is false
order by pays;
-- 294

/*
196	Nouméa (Aéroport de - Nouvelle Calédonie)	France	doute
1543	TOULOUSE  - CADA	France	vérifiée
202	Païta (Nouvelle-Calédonie)	France	doute
189	Propriano (Port de)	France	doute
165	Ajaccio (Port de)	France	FRA	doute
112	Marseille (Arenc)	France	FRA	doute

281	Igoumenitsa (Police Station)	Greece
657	Skaramangas	Greece
306	Lesbos Harbor	Greece
279	Igoumenitsa (Container port police)	Greece
280	Igoumenitsa (Police Station)	Greece
*/
select * from demographie."GISCO_LAU_eurostat" where comm_name = 'Propriano';
-- 862211
update camps.camps6 set eurostat_pop_2019 = 862211 where unique_id = '112' and nom = 'Marseille (Arenc)';
update camps.camps6 set eurostat_pop_2019 = 69075 where unique_id = '165' and nom = 'Ajaccio (Port de)';
update camps.camps6 set eurostat_pop_2019 = 3789 where unique_id = '189' and nom = 'Propriano (Port de)';

-- Attention, il n'y a pas eu de diagnostique ville sur la grece dans demographie."GISCO_LAU_eurostat"
-- en effet, ligne 1017 C:\Travail\MIGRINTER\Labo\Louis_Fernier\osm_extract.sql
--  computed_gisco_id = g.nuts_code||g.nsi_code = eu."NUTS 3 CODE"||eu."LAU CODE"
select * from demographie."GISCO_LAU_eurostat" where cntr_code  = 'EL';
select * from demographie."GISCO_LAU_eurostat" where name_asci  = 'Igoumenitsas';
select * from demographie."GISCO_LAU_eurostat" where name_asci  in ('Igoumenitsas', 'Toulouse');
-- Igoumenitsas	EL542	GR02042001 mais pas de pop ni de fua code
select * from demographie.eu where "NUTS 3 CODE" = 'EL542';
select * from demographie.eu where "NUTS 3 CODE" = 'EL542' order by population ;


---------------------------------------------
-- SAGEO25
-- pays_population : 2019
-- Données banque mondiale : https://donnees.banquemondiale.org/indicator/SP.POP.TOTL?end=2023&start=2023&view=map
-- sauf n°1 Kosovo et n°1679	Centre de détention de Laâyoune	Western Sahara	ESH
---------------------------------------------

select unique_id, nom, pays, iso3 , c.localisation_qualite 
from camps.camps6 c where pays_population is  null and geom is not null
order by pays;
-- 231


update  camps.camps6 c set pays_population = pm."2019"
from demographie.population_monde pm 
where c.iso3 = pm.country_code 
-- 1788 

update  camps.camps6 c set pays_population = w.pop_est 
from demographie.ne_10m_admin_0_countries w 
where pays_population is null and (w.name_fr=c.pays or w.adm0_a3_fr=c.iso3)
-- 1 (kosovo)
-- 1679	Centre de détention de Laâyoune	Western Sahara	ESH	commune

select c.unique_id, w.adm0_a3_fr , w.name_fr, c.nom, c.iso3, c.pays, c.unique_id 
from demographie.ne_10m_admin_0_countries w, camps.camps6 c
where c.iso3 is not null and st_contains(w.geom, c.geom) and  w.adm0_a3_fr<>c.iso3;


-- ville_proche_nom
-- ville_proche_code postal
-- ville_proche_population


-------------------------------------------------------
-- Renseigner ville_proche_nom : prendre le nom de la city ou fua sinon
-- Renseigner ville_proche_population : prendre la population de la city ou de la fua si celle-ci est renseignée
-- se reporter ensuite au script C:\Travail\MIGRINTER\Labo\Louis_Fernier\Analyse_camp_Nov2024\demographie_camps.sql
-------------------------------------------------------
select unique_id , nom, pays, ville_proche_nom, distance_ville_proche, ville_proche_population , REPLACE (distance_ville_proche, ' ', '') 
from camps.camps6 
where unique_id = 165;

select unique_id , nom, pays, ville_proche_nom, distance_ville_proche,  trim(REPLACE (distance_ville_proche, ' ', '')) 
from camps.camps6 
where 
-- distance_ville_proche = '1 140'; 1 140
position(' ' in distance_ville_proche) >= 0;

update camps.camps6  set distance_ville_proche = '1258' where distance_ville_proche = '1 258';
update camps.camps6  set distance_ville_proche = trim(REPLACE (distance_ville_proche, ' ', ''))  where position(' ' in distance_ville_proche) >= 0;

alter table camps.camps6 alter column distance_ville_proche type float using distance_ville_proche::float;

-- 0 si dans la grande ville (catégorie C des aires_urbaines)
-- km sinon du camps au coeur de la city la plus proche

select c.nom, camp_commune , au.urau_name, au.city_pop2019 ,
case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end
from camps.camps6 c, demographie.aires_urbaines au 
where au.urau_catg = 'C' and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code;
 
update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = 0
from demographie.aires_urbaines au 
where ville_proche_nom is null and au.urau_catg in ('C', 'K') and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code;
-- 172 + 311 : c'est OK

update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = 0 
from demographie.aires_urbaines au 
where distance_ville_proche  > 100 and au.urau_catg in ('C', 'K') 
and st_contains(au.geom, c.point3857);
-- 16

update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = 0, 
eurostat_computed_city_code  = au.urau_code
from demographie.aires_urbaines au 
where au.urau_catg in ('C', 'K') 
and st_contains(au.geom, c.point3857);
-- 609
-- le 7/10/2024


-- and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code;


--demographie.aires_urbaines est un import de C:\Travail\MIGRINTER\Labo\Louis_Fernier\GrosFichiers - LOUIS FERNIER\17mars22-envoi\Audit_urbain-2020-100k.shp\URAU_RG_100K_2020_3857.shp
select * from demographie.aires_urbaines au 
where au.fua_code  = 'BE002L2';
select * from demographie.aires_urbaines au 
where au.urau_name  = 'Antwerpen';

-- modification 4.10.2025: on connait la FUA : si le camps est dedans, on met 0 en distance
-- sinon on prend la distance à son enveloppe
update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = 0
from demographie.aires_urbaines au 
where distance_ville_proche is null  and st_contains(au.geom, c.point3857);
-- 1 + 239
-- and eurostat_computed_city_code is not null and eurostat_computed_city_code = au.urau_code;


-- modification 7.10.2025: on connait la FUA : si le camps est dedans, on met distance au centre de la FUA du même code
update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = round(st_distance(c.point3857, cu.geom)/1000)
from demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where distance_ville_proche is null and st_contains(au.geom, c.point3857) and cu.urau_code = au.urau_code;
-- 0

select c.unique_id, c.nom, c.pays, camp_commune, ville_proche_nom, au.urau_catg, 
case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population, au.city_pop2019::float,
distance_ville_proche,  round(st_distance(c.point3857, cu.geom)/1000)
from camps.camps6 c, demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where   st_contains(  au.geom, c.point3857) and cu.urau_code = au.urau_code 
and c.pays='Greece';
--and distance_ville_proche<> 0
-- au.urau_catg = 'F' and
order by c.pays;

select  au.urau_catg, count(*) 
from demographie.aires_urbaines au
group by au.urau_catg;
-- ICI 07/10

select c.unique_id, c.nom, c.pays, camp_commune, ville_proche_nom, 
au.urau_catg, case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population, 
distance_ville_proche, round(st_distance(c.point3857, st_centroid(au.geom))/1000)
--,  round(st_distance(c.point3857, cu.geom)/1000)
from camps.camps6 c,  demographie.aires_urbaines au
-- , demographie.aires_urbaines au2,  demographie.centres_aires_urbaines  cu
where   st_contains(  au.geom, c.point3857) 
-- and st_contains(au.geom, au2.geom) 
--- and st_intersects(  au.geom, cu.geom)
-- and cu.urau_code = au2.urau_code 
and c.pays='Greece'
and distance_ville_proche<> 0
and au.urau_catg = 'F' 
--and au2.urau_catg <> 'F' 
order by c.pays, c.unique_id;

-- modification 7.10.2025: on connait la FUA : si le camps est dedans, on met distance au centre de la FUA du même code
update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = round(st_distance(c.point3857, st_centroid(au.geom))/1000),
eurostat_computed_fua_code = au.urau_code
from demographie.aires_urbaines au
where st_contains(au.geom, c.point3857) and au.urau_catg = 'F' 
and distance_ville_proche<> 0 and distance_ville_proche > round(st_distance(c.point3857, st_centroid(au.geom))/1000) 
 ;
-- 44

select unique_id, nom, pays  , c.distance_ville_proche
from demographie.aires_urbaines au , camps.camps6 c 
where au.urau_code = 'EL001L1'
and st_contains(au.geom, c.point3857);
-- camps en grece : pourquoi distance loin si athens (309,299, 269 )

select c.nom, camp_commune , au.urau_name, au.fua_pop2019 ,
case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end
from camps.camps6 c, demographie.aires_urbaines au 
where c.distance_ville_proche is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code;
 -- 240

-- FUA of the Greater City of Paris
update camps.camps6 c 
set ville_proche_nom = case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end,
ville_proche_population = au.fua_pop2019::float
from demographie.aires_urbaines au 
where ville_proche_nom is null and ville_proche_population is null and au.urau_catg = 'F' and eurostat_computed_fua_code is not null and eurostat_computed_fua_code = au.urau_code;
-- 185 


select unique_id , nom, pays, eurostat_computed_city_code , eurostat_computed_fua_code , eurostat_name_ascii_2016 , ville_proche_nom, distance_ville_proche, ville_proche_population 
from camps.camps6 
--order by nom;
where unique_id = 168;

select unique_id , nom, pays, eurostat_nuts_code_2016 , eurostat_name_ascii_2016 , ville_proche_nom, distance_ville_proche, ville_proche_population 
from camps.camps6 
where eurostat_computed_city_code is null and eurostat_computed_fua_code is null and horsdburba is false;
-- eurostat_computed_city_code , eurostat_computed_fua_code , 

select unique_id , nom, pays, eurostat_nuts_code_2016 , ville_proche_nom, distance_ville_proche, 
eurostat_name_ascii_2016 , ville_proche_nom, eurostat_computed_city_code, eurostat_computed_fua_code 
from camps.camps6 
where (eurostat_computed_city_code is not null or eurostat_computed_fua_code is not null) and horsdburba is false
order by distance_ville_proche desc;
-- 863

select unique_id , nom, pays, eurostat_nuts_code_2016 , ville_proche_nom, distance_ville_proche, 
eurostat_name_ascii_2016 , ville_proche_nom, eurostat_computed_city_code, eurostat_computed_fua_code 
from camps.camps6 
where distance_ville_proche is null and horsdburba is false 
order by pays;

------
-- ici 15h49 lundi

update camps.camps6 c 
 

select case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end as ville_proche_nom,
 au.city_pop2019::float as ville_proche_population,
 round(st_distance(c.point3857, st_centroid(au.geom))/1000) as distance_ville_proche,
  au.urau_code as eurostat_computed_fua_code
from demographie.aires_urbaines au, camps.camps6  c
where point3857 is not null and au.urau_catg = 'F' 
and distance_ville_proche is null and horsdburba is false 
 ;

select c.unique_id, c.nom, c.pays,
	case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end as ville_proche_nom,
	 au.city_pop2019::float as ville_proche_population,
 	round(st_distance(c.point3857, st_centroid(au.geom))/1000) as distance_ville_proche,
  	au.urau_code as eurostat_computed_fua_code
from demographie.aires_urbaines au, 
	camps.camps6  c,
	(select c.unique_id, c.nom,
	min(round(st_distance(c.point3857, st_centroid(au.geom))/1000)) as dmin
	from demographie.aires_urbaines au, camps.camps6  c
	where point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false 
	group by unique_id, nom) as k
where 
	point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false  and
	round(st_distance(c.point3857, st_centroid(au.geom))/1000) = k.dmin
	and c.unique_id = k.unique_id 
 ;
 -- 353 en 33s


 update camps.camps6  c
 set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
	ville_proche_population = au.city_pop2019::float,
	distance_ville_proche = round(st_distance(c.point3857, st_centroid(au.geom))/1000),
	eurostat_computed_fua_code = au.urau_code
from demographie.aires_urbaines au, 
	(select c.unique_id, c.nom,
	min(round(st_distance(c.point3857, st_centroid(au.geom))/1000)) as dmin
	from demographie.aires_urbaines au, camps.camps6  c
	where point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false 
	group by unique_id, nom) as k
where 
	point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false  and
	round(st_distance(c.point3857, st_centroid(au.geom))/1000) = k.dmin
	and c.unique_id = k.unique_id 
	
------------------------------------------------------------------------------------------------- 
-- SAGEO25 -- step 1
update camps.camps6 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population = au.city_pop2019::float,
distance_ville_proche = round(st_distance(c.point3857, cu.geom)/1000)
from demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where distance_ville_proche is null and st_contains(au.geom, c.point3857) and cu.urau_code = au.urau_code;

select c.nom_court,
case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
round(st_distance(c.point3857, cu.geom)/1000) as d, au.city_pop2019::float as pop
from camps.camps6 c , demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where st_contains(au.geom, c.point3857) and cu.urau_code = au.urau_code
and c.unique_id=1252;

select c.nom_court, au.urau_code, au.*
from camps.camps6 c , demographie.aires_urbaines au
where st_contains(au.geom, c.point3857)  and c.unique_id=130;

select c.nom_court, au.urau_code, au.*, cu.*
from camps.camps6 c , demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where st_contains(au.geom, c.point3857) and cu.fua_code = au.urau_code  and c.unique_id=130;

-- les camps dans les kernels : prendre la distance min
select c.nom_court, round(st_distance(c.point3857, cu.geom)/1000) as d, au.urau_code, au.*, cu.*
from camps.camps6 c , demographie.aires_urbaines au, demographie.centres_aires_urbaines  cu
where st_contains(au.geom, c.point3857) and cu.city_kern = au.urau_code  and c.unique_id=130;


-- SAGEO25 -- step 2
 update camps.camps6  c
 set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
	ville_proche_population = au.city_pop2019::float,
	distance_ville_proche = round(st_distance(c.point3857, st_centroid(au.geom))/1000),
	eurostat_computed_fua_code = au.urau_code
from demographie.aires_urbaines au, 
	(select c.unique_id, c.nom,
	min(round(st_distance(c.point3857, st_centroid(au.geom))/1000)) as dmin
	from demographie.aires_urbaines au, camps.camps6  c
	where point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false 
	group by unique_id, nom) as k
where 
	point3857 is not null and au.urau_catg = 'F' 
	and distance_ville_proche is null and horsdburba is false  and
	round(st_distance(c.point3857, st_centroid(au.geom))/1000) = k.dmin
	and c.unique_id = k.unique_id 
 ;
-- le 7.10.2025, 353 lignes en 66 s

-- le 30.12.2024 : des villes sont renseignées pour la distance, mais pas pour la population
select ville_proche_nom from camps.camps6
where distance_ville_proche is not null and ville_proche_population is null ;

select c.unique_id, c.nom, c.pays, camp_commune, ville_proche_nom, 
au.urau_catg, case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population, au.city_pop2019::float, au.fua_pop2019,
distance_ville_proche, round(st_distance(c.point3857, st_centroid(au.geom))/1000)
--,  round(st_distance(c.point3857, cu.geom)/1000)
from camps.camps6 c,  demographie.aires_urbaines au
-- , demographie.aires_urbaines au2,  demographie.centres_aires_urbaines  cu
where   st_contains(au.geom, c.point3857) 
-- and st_contains(au.geom, au2.geom) 
--- and st_intersects(  au.geom, cu.geom)
-- and cu.urau_code = au2.urau_code 
 and c.pays='Greece'
and ville_proche_population is  null
-- and au.urau_catg = 'F' 
--and au2.urau_catg <> 'F' 
order by c.pays, c.unique_id;


-- SAGEO25
-- tout revoir sur la démographie des villes proches. Ainsi que sur la distance. 

select c.unique_id, c.nom, c.pays, camp_commune, ville_proche_nom, 
au.urau_catg, case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
ville_proche_population, au.computed_pop_2020
distance_ville_proche, round(st_distance(c.point3857, st_centroid(au.wkb_geometry))/1000)
from camps.camps7 c,  demographie.urau_rg_100k_2020_3857 au 
where   st_contains(wkb_geometry, c.point3857) 
and ville_proche_population is  null
order by c.pays, c.unique_id;
-- OK  tout est à jour depuis le 05.01.2025




------------------------------------------------------------------------------------------
/*
select  c.unique_id , c.nom, camp_commune , au.urau_code, au.urau_name, au.urau_catg, nuts3_2016, nuts3_2021, round(st_distance(c.point3857, au.geom)/1000) as d
from camps.camps6 c , demographie.centres_aires_urbaines au ,
	(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
	from camps.camps6 c  , demographie.centres_aires_urbaines au 
	where au.urau_catg = 'C' and ville_proche_nom is null and ville_proche_population is null
	group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id;
-- 617

select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id
-- 662
*/

alter table camps.camps3 add column eurostat_nuts_code_2016_level3 text ;
alter table camps.camps3 add column eurostat_nuts_code_2021_level3 text ;

/*
update camps.camps3 c 
set ville_proche_nom = case when position('City of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 9) end,
distance_ville_proche = round(st_distance(c.point3857, au.geom)/1000),
eurostat_nuts_code_2016_level3 = au.nuts3_2016 ,
eurostat_nuts_code_2021_level3 = au.nuts3_2021
from 
 demographie.centres_aires_urbaines au ,
(select  c.unique_id , min(st_distance(c.point3857, au.geom)) as dmin
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C'
group by c.unique_id) as k 
where st_distance(c.point3857, au.geom) = k.dmin and c.unique_id = k.unique_id
*/
-- 617
-- NON, foaut pas faire çà

select * from demographie.eu e 
where "NUTS 3 CODE" like 'S%'
order by e."LAU NAME LATIN" ;



-- where gisco_id  = 'RS_70360'
where e."LAU NAME NATIONAL"  ilike '%Sjenica%';


select unique_id , nom, pays, 
ville_proche_nom, distance_ville_proche, ville_proche_population,
eurostat_computed_fua_code, eurostat_computed_city_code , 
eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3 ,
eurostat_pop_2019 
from  camps.camps6 
where pays = 'Italy';
-- ville_proche_nom is not null and ville_proche_population is null and unique_id = 862;

-- and pays = 'Italy';

/*
-- il faut renseigner la pop avec la population du NUTS3 associé à la ville la plus proche
-- eurostat_nuts_code_2016_level3 
-- exemple : Lampedusa - Contrada Imbriacola (Agrigento)  est à 215 km de milan (MT001)
select  c.unique_id , min(st_distance(c.point3857, au.geom))
from camps.camps3 c  , demographie.centres_aires_urbaines au 
where au.urau_catg = 'C' and ville_proche_nom is null 
group by c.unique_id
*/

-- Non finalement, on remplace par la population de la commune quand le camp n'est ni dans une FUA ni une City 
-- 7/10/2024 : Non, on a pris la distance à la ville au sens FUA finalement. 


/*
update camps.camps3 c set ville_proche_population = eurostat_pop_2019 
where eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019::int <> -1

select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps3 
where ville_proche_nom is not null and ville_proche_population is null and eurostat_computed_gisco_id is not null 
and eurostat_pop_2019::int <> -1
-- 132 entités
except (
select unique_id, pays, camp_commune, eurostat_computed_gisco_id , eurostat_name_ascii_2016 , eurostat_pop_2019 , distance_ville_proche, ville_proche_nom, ville_proche_population, eurostat_computed_city_code, eurostat_computed_fua_code
from  camps.camps3 
where  eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019::int <> -1)
-- 128 entités


select * from demographie.aires_urbaines au 
where au.urau_code in ('HU001C1','FR030L1', 'FR028L1', 'FR030L1', 'HU001L2', 'IE001L1', 'IE002L1', 'IE001L1', 'IE001L1', 'IE001L1', 'IE003L1', 'NO001L1')
*/
/*
HU001L2 1245672
HU001C1 
FR028C1	FR028L1
FR028L1
FR521L1
FR521L1
FR030L1
NO001L1
FR030L1
*/

/*
set ville_proche_nom = case when position('FUA of' in au.urau_name) = 0 then au.urau_name else substring(au.urau_name from 8) end,
ville_proche_population = au.fua_pop2019
from camps.camps3 c, "GISCO_LAU_eurostat" is
where c.eurostat_computed_gisco_id 
*/

alter table camps.camps6 alter column eurostat_pop_2019 type int using eurostat_pop_2019::int;
update camps.camps6 set eurostat_pop_2019 = null where eurostat_pop_2019= -1
-- 216

-- update camps.camps6 c set ville_proche_population = eurostat_pop_2019 
-- where eurostat_computed_city_code is null and eurostat_computed_fua_code is  null and eurostat_pop_2019 is not null


select horsdburba, count(unique_id), avg(distance_ville_proche) as moy_distance_ville
--, avg(ville_proche_population) as moy_pop_ville
from camps.camps6 c
where c.geom is not null
group by (distance_ville_proche is not null), horsdburba ;
--, (ville_proche_population is not null);

select count(unique_id) as nb_camps, pays, array_agg(unique_id)  , array_agg(nom)  
-- ,  count(distance_ville_proche) as nb_distance_complete, count(distance_ville_proche)/count(unique_id)*100 as taux_complet
from camps.camps6 c
where c.geom is not null and ( distance_ville_proche is null)
group by pays
order by  nb_camps asc;
-- 244 

-- SAGEO25

select count(unique_id) as nb_camps, pays, 
count(distance_ville_proche) as nb_distance_complete,  count(distance_ville_proche)*1.0/count(unique_id)*100 as taux_complet,
array_agg(unique_id)  , array_agg(nom), array_agg(distance_ville_proche)
from camps.camps7 c
where c.geom is not null and doublon= 'Non' --and ( distance_ville_proche is null)
group by pays
order by   count(distance_ville_proche)*1.0/count(unique_id)*100 asc, nb_camps;

-- count(ville_proche_population)  as nb_pop_complete,
-- 2/4	Belarus
-- 26/45	Turkey
-- 8/13	Bosnia and Herzegovina
-- Belarus
-- Bosnia and Herzegovina
-- Egypt

--------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Traitement OSM
-- creation d'une vue combinant les données (bosnie, belgium, denmark, netherlands, france)

CREATE INDEX sidx_camps66_point3857 ON camps.camps6 USING gist (point3857);


--mairie_distance
select unique_id , nom , iso3, distance_ville_proche, mairie_distance, atm_distance, hopital_distance,pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, avocat_hors_camp_distance_km --, replace(mairie_distance, ',', '.') 
from camps.camps6 c 
where  geom is not null and iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA')
order by iso3;
-- 825
-- reprise du script C:\Travail\MIGRINTER\Labo\Louis_Fernier\osm_extract.sql ligne 2235

-- update camps.camps6 set mairie_distance = null where mairie_distance = '';
-- alter table camps.camps5 alter column mairie_distance type float using replace(mairie_distance, ',', '.')::double precision;


update camps.camps6  c set mairie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity='townhall' or building = 'townhall') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity='townhall' or building = 'townhall' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and c.mairie_distance is null;
-- 825

/*
select c.unique_id , c.nom ,st_distance(osm.way, c.point3857) as dkm, osm.*
from public.osm_point osm , camps.camps6  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null;
-- -- 129	Palaiseau	525.3589981989759

select c.unique_id , c.nom , min(st_distance(osm.way, c.point3857)) as dkm
from public.osm_polygon osm , camps.camps6  c
where c.unique_id = 129 and (amenity='townhall' or building = 'townhall')  and c.point3857 is not null
group by c.unique_id , c.nom;

alter table france.planet_osm_polygon add column new_id serial;
-- 20 min
select count(*) from france.planet_osm_polygon -- 54517680
*/

-- vérification que les vues sur OSM fonctionnent bien

select count(*) from public.osm_point where amenity='townhall' or building = 'townhall';--754 (avant France) à 17288 (avec France)
select count(*) from public.osm_polygon where amenity='townhall' or building = 'townhall';--771 (avant France) à 21699 (avec France)

select count(*) from france.planet_osm_point where amenity='townhall' or building = 'townhall';--16537
select count(*) from france.planet_osm_point where amenity='townhall' or building = 'townhall';--16537


select mairie_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.mairie_distance !='' 
-- and lcb.iso3  in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');
-- 36 lignes mais pas dans ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');

/*
update camps.camps6 c set mairie_distance = replace(lcb.mairie_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.mairie_distance != ''; --36
*/

-- atm
--update camps.camps6 set atm_distance = null where atm_distance = '';
--alter table camps.camps6 alter column atm_distance type float using replace(atm_distance, ',', '.')::double precision;

update camps.camps6  c set atm_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity='atm') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity='atm' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and c.atm_distance is null;
--  825 en 3 min 

/*
update camps.camps6 c set atm_distance = replace(lcb.atm_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.atm_distance != '';--0
*/

-- hopital_distance
--update camps.camps6 set hopital_distance = null where hopital_distance = '';
--alter table camps.camps6 alter column hopital_distance type float using replace(hopital_distance, ',', '.')::double precision;

update camps.camps6  c set hopital_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('hospital', 'clinic') or building in ('hospital', 'clinic')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and hopital_distance is null;
--  

--select hopital_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.hopital_distance !='' and lcb.iso3 not in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');
/*
update camps.camps6 c set hopital_distance = replace(lcb.hopital_distance, ',', '.')::double precision
from camps.lfernier_bdd_10oct2023  lcb
where lcb.unique_id = c.unique_id  and lcb.hopital_distance != '';--36
*/

-- pharmacie_distance
-- update camps.camps6 set pharmacie_distance = null where pharmacie_distance = '';
-- alter table camps.camps6 alter column pharmacie_distance type float using replace(pharmacie_distance, ',', '.')::double precision;

update camps.camps6  c set pharmacie_distance = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('pharmacy') or shop in ('chemist', 'medical_supply')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and pharmacie_distance is null;
-- 825

-- select pharmacie_distance from camps.lfernier_bdd_10oct2023  lcb where lcb.pharmacie_distance !='' and lcb.iso3  in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA');



-- arret_bus_distance_km
--update camps.camps6 set arret_bus_distance_km = null where arret_bus_distance_km = '';
--alter table camps.camps6 alter column arret_bus_distance_km type float using replace(arret_bus_distance_km, ',', '.')::double precision;


update camps.camps6  c set arret_bus_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('bus_station') or highway='bus_stop' or public_transport='platform' or  railway='platform') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and arret_bus_distance_km is null;
-- 825


-- gare_distance_km
-- update camps.camps6 set gare_distance_km = null where gare_distance_km = '';
-- alter table camps.camps6 alter column gare_distance_km type float using replace(gare_distance_km, ',', '.')::double precision;

update camps.camps6  c set gare_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (railway='station' or railway='halt' or building='train_station' or  public_transport='station' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and gare_distance_km is null;
-- 825


-- medecin_clinique_hors_camp_distance_km
-- update camps.camps6 set medecin_clinique_hors_camp_distance_km = null where medecin_clinique_hors_camp_distance_km = '';
-- alter table camps.camps6 alter column medecin_clinique_hors_camp_distance_km type float using replace(medecin_clinique_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps6  c set medecin_clinique_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('clinic', 'doctors') or building in ('clinic', 'healthcare')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and medecin_clinique_hors_camp_distance_km is null;
-- 825

select iso3, medecin_clinique_hors_camp_distance_km 
from camps.camps6  c
where c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
order by iso3;

-- dentiste_hors_camp_distance_km
-- update camps.camps6 set dentiste_hors_camp_distance_km = null where dentiste_hors_camp_distance_km = '';
-- alter table camps.camps6 alter column dentiste_hors_camp_distance_km type float using replace(dentiste_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps6  c set dentiste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('dentist') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and dentiste_hors_camp_distance_km is null;
-- 825


-- avocat_hors_camp_distance_km
-- update camps.camps6 set avocat_hors_camp_distance_km = null where avocat_hors_camp_distance_km = '';
-- alter table camps.camps6 alter column avocat_hors_camp_distance_km type float using replace(avocat_hors_camp_distance_km, ',', '.')::double precision;

update camps.camps6  c set avocat_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (office = 'lawyer' ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (office = 'lawyer') and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and avocat_hors_camp_distance_km is null;
-- 825




-- poste_hors_camp_distance_km
-- Pour poste : post_box / post_office
-- update camps.camps6 set poste_hors_camp_distance_km = null where poste_hors_camp_distance_km = '';
alter table camps.camps6 add column poste_hors_camp_distance_km float;

update camps.camps6  c set poste_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('post_box', 'post_office') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('post_box', 'post_office')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and poste_hors_camp_distance_km is null;
-- 819 , 2 min 15 s


select column_name, data_type 
from information_schema.columns 
where table_name = 'lfernier_bdd_10oct2023' and column_name like '%distance%' ;

-- UPDATED
--mairie_distance	character varying
-- ecole_hors_camp_distance_km
--atm_distance	character varying
--hopital_distance	character varying
--pharmacie_distance	character varying
--medecin_clinique_hors_camp_distance_km	character varying
--dentiste_hors_camp_distance_km	character varying
--arret_bus_distance_km	character varying
--gare_distance_km	character varying
--avocat_hors_camp_distance_km	character varying
-- poste_hors_camp_distance_km

-- UNDONE
/*
installation_electrique_distance_km	character varying
station_epuration_distance_km	character varying
dechetterie_distance_km	character varying
carriere_distance_km	character varying
voie_ferree_distance_km	character varying
usine_chimique_distance_km	character varying
usine_chimique_zone_contaminee_distance_km	character varying
danger_zone_distance_km	character varying
aeroport_distance_km	character varying
autoroute_distance_km	character varying
voie_rapide_distance_km	character varying
pesticides_distance_km	character varying
seveso_distance_km	character varying
natura_2000_distance_km	character varying
nucléaire_zone_radioactive_distance_km	character varying
zone_minee_distance_km	character varying
champ_de_tir_distance_km	character varying
munitions_non_explosees_distance_km	character varying
*/



-- Pour école : school / college
-- alter table camps.camps6 add column ecole_hors_camp_distance_km numeric;
alter table camps.camps6 add column ecole_hors_camp_distance_km float;

update camps.camps6  c set ecole_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college') ) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('BIH', 'DNK', 'NLD', 'BEL', 'FRA') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and ecole_hors_camp_distance_km is null;
-- 825

-- df -H 
-- /dev/mapper/externe-data           633G    349G  253G  58% /data

-----------------------------------------------
-- le 07 octobre 2024 : extraction 
select unique_id, nom, type_camp , ville_proche_nom , pays, gare_distance_km , arret_bus_distance_km , pharmacie_distance , hopital_distance , atm_distance , mairie_distance , clc_majoritaire_3   
from camps.camps6 where geom is not null and pays in ('Bosnia and Herzegovina', 'Denmark');


select column_name, data_type 
from information_schema.columns 
where table_name = 'camps5';

select "pays_community health workers (per 1,000 people)" from camps.camps5 c where "pays_community health workers (per 1,000 people)" != '';
select "pays_hospital beds (per 1,000 people)" from camps.camps5 c where "pays_hospital beds (per 1,000 people)" != '';
select "camps_community health workers (per 1,000 people)" from camps.camps5 c where "camps_community health workers (per 1,000 people)" != '';

select column_name 
from  information_schema.columns 
where table_name = 'camps5' and column_name like 'pays_%' ;


select string_agg(column_name, ', ') 
from  information_schema.columns 
where table_name = 'camps5' and column_name not like 'field_%' and column_name not like 'point%';

update camps.camps5 set sources = regexp_replace(sources, '\n', ' - ', 'g');


select unique_id, id, nom, nom_court, doublon, remarques, bdd_source, sources, iso3, pays, pays_population, "ouverture/premiere_date", fermeture_date, derniere_date_info, actif_dernieres_infos, localisation_qualite, camp_latitude, camp_longitude, url_maps, camp_adresse, camp_code_postal, camp_commune, 
ville_proche_nom, "ville_proche_code postal", ville_proche_population, 
prison, type_camp, infrastructure, climat, zone, occupation_du_sol, capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
mairie_distance, mairie_temps_pied, atm_distance, atm_temps_pied, hopital_distance, hopital_temps_voiture, pharmacie_distance, pharmacie_temps_pied, medecin_presence, transports_publics_camp_regularite, transports_publics_ville_proche_regularite, arret_bus_distance_km, arret_bus_temps, gare_distance_km, gare_temps, medecin_clinique_hors_camp_distance_km, medecin_clinique_hors_camp_temps, dentiste_hors_camp_distance_km, dentiste_hors_camp_temps, 
eau_accès, collecte_dechets, electricite, energie_autre, toilettes, douche, sanitaires_separation, travail_non, travail_oui, education_publique, education_associations, avocat_camp_presence, risque_environnemental, 
avocat_hors_camp, avocat_hors_camp_distance_km, installation_electrique, installation_electrique_distance_km, station_epuration, station_epuration_distance_km, dechetterie, dechetterie_distance_km, carriere, carriere_distance_km, voie_ferree, voie_ferree_distance_km, usine_chimique, usine_chimique_distance_km, usine_chimique_zone_contaminee, usine_chimique_zone_contaminee_distance_km, danger_zone, danger_zone_distance_km, aeroport, aeroport_distance_km, autoroute, autoroute_distance_km, voie_rapide, voie_rapide_distance_km, pesticides, pesticides_distance_km, seveso, seveso_distance_km, natura_2000, natura_2000_distance_km, nucléaire_zone_radioactive, nucléaire_zone_radioactive_distance_km, zone_minee, zone_minee_distance_km, champ_de_tir, champ_de_tir_distance_km, munitions_non_explosees, munitions_non_explosees_distance_km, 
"pays_community health workers (per 1,000 people)", "camps_community health workers (per 1,000 people)", "pays_hospital beds (per 1,000 people)", "pays_mortality rate attributed to household and ambient air pol", "camp_mortality rate attributed to household and ambient air pol", "pays_suicide mortality rate (per 100,000 population)", "camp_suicide mortality rate", "pays_mortality rate attributed to unsafe water, unsafe sanitati", "camp_mortality rate attributed to unsafe water, unsafe sanitati", 
pays_nombre_undernourished_people, camp_nombre_undernourished_people, pays_pourcentage_undernourished_people, camp_pourcentage_undernourished_people, "pays_people using at least basic drinking water services (% of", "camp_people using at least basic drinking water services (% of", "pays_hypertension_adultes_pourcentage", camp_hypertension_adultes_pourcentage, pays_traitement_hypertension_adultes_pourcentage, camp_traitement_hypertension_adultes_pourcentage, "pays_death_by_communicable_diseases (% of total)", 
camp_maladies_infectieuses, pays_maladies_infectieuses, ville_proche_maladies_infectieuses, camp_maladies_mentales, pays_maladies_mentales, ville_proche_maladies_mentales, malnutrition, "camp_death_by_communicable_diseases (% of total)", "pays_death_by_non_communicable_diseases (% of total)", "camp_death_by_non_communicable_diseases (% of total)", 
chauffage_ventilation, mouvement_de_terrain, intemperies, tempetes, orages_et_foudres, grele, tornade_et_trombe, incendies, inondations_et_coulees_de_boue, marecages, seismes, froid_neige_pluies_verglacantes, secheresses, canicules, tensions_population_locale, raison_encampement, surveillance_qui, surveillance_nombre, surveillance_mission, surveillance_comportement, turnover_encampes, modification_cadre_de_vie, organisations_nombre, organisations_reunions_annuelles_nombre, environnement_plan_global, manifestaions_possibles, 
tentes_places, rubhall_places, containers_places, prefabriques_places, dur_places, hebergement_choix_possible, hebergement_changement_possible, herbergement_modification_possible, 
aide_financière, alimentation_distributions, alimentation_cuisine, vetements_distribution, vetements_adaptes, 
eurostat_computed_gisco_id, eurostat_computed_city_code, eurostat_computed_fua_code, eurostat_nuts_code_2016, eurostat_nsi_code_2016, eurostat_name_ascii_2016, eurostat_pop_2019, distance_ville_proche, eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3, degurba, 
clc_majoritaire_3, clc_majoritaire_4, distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, distancesc, gestionnaire_principal, 
ecole_hors_camp_distance_km, poste_hors_camp_distance_km, distanceschengenkm, 
geom
from camps.camps6 c ;
-- export complet

select unique_id, id, nom, doublon,  bdd_source,
localisation_qualite, camp_latitude, camp_longitude, 
iso3, pays, pays_population , derniere_date_info ,
"ouverture/premiere_date",
fermeture_date,
derniere_date_info,
actif_dernieres_infos,
-- url_maps, 
camp_adresse, camp_code_postal, camp_commune, 
-- ville_proche_nom, ville_proche_population, 
prison, type_camp, 
-- eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3, 
degurba, horsdburba, 
ville_proche_nom , distance_ville_proche, ville_proche_population , "ville_proche_code postal",
eurostat_name_ascii_2016, eurostat_pop_2019,
infrastructure, climat, zone, occupation_du_sol, 
-- capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
--mairie_temps_pied, atm_temps_pied, , hopital_temps_voiture, pharmacie_temps_pied, medecin_presence, transports_publics_camp_regularite, 
--transports_publics_ville_proche_regularite, arret_bus_temps, gare_temps, medecin_clinique_hors_camp_temps, dentiste_hors_camp_temps, 
-- eurostat_computed_gisco_id, eurostat_computed_city_code, eurostat_computed_fua_code, eurostat_nuts_code_2016, eurostat_nsi_code_2016, 
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
order by pays ;
-- 2024.10.08_camp6_extractionSimple.csv
-- 2024.10.10_camp6_extractionSimple.csv

select unique_id, id, nom, iso3, pays, 
localisation_qualite, camp_latitude, camp_longitude, 
pays_population , derniere_date_info ,
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
order by pays ;
----------------------------------------------------------------------------------
-- import des autres pays OSM
italy, poland, spain
albania
austria

cd /data/osm
wget https://download.geofabrik.de/europe/belgium-latest.osm.pbf


-- Import  italie
export PGPASSWORD="******"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/italy-latest.osm.pbf > out.txt &
-- 1473 s 

create schema italy;
alter table planet_osm_point set schema italy;
alter table planet_osm_line set schema italy;
alter table planet_osm_polygon set schema italy;
alter table planet_osm_roads set schema italy;

-- Import  Pologne
export PGPASSWORD="******"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/poland-latest.osm.pbf > out.txt &

create schema poland;
alter table planet_osm_point set schema poland;
alter table planet_osm_line set schema poland;
alter table planet_osm_polygon set schema poland;
alter table planet_osm_roads set schema poland;

-- Import  spain
export PGPASSWORD="*******"
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/spain-latest.osm.pbf > out.txt &

select     table_schema || '.' || table_name as show_tables
from     information_schema.tables
where     table_type = 'BASE TABLE' AND
    table_schema NOT IN ('pg_catalog', 'information_schema');
   
select table_schema || '.' || table_name as show_tables from information_schema.tables where table_type = 'BASE TABLE' and table_schema  IN ('public');

/*
-- Import  united-kingdom
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/united-kingdom-latest.osm.pbf > out.txt &

create schema united_kingdom;
alter table planet_osm_point set schema united_kingdom;
alter table planet_osm_line set schema united_kingdom;
alter table planet_osm_polygon set schema united_kingdom;
alter table planet_osm_roads set schema united_kingdom;

-- Import  germany
nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/germany-latest.osm.pbf > out.txt &

create schema germany;
alter table planet_osm_point set schema germany;
alter table planet_osm_line set schema germany;
alter table planet_osm_polygon set schema germany;
alter table planet_osm_roads set schema germany;

-- Import  guernsey-jersey

nohup osm2pgsql -d osm -U postgres -c -s --drop  /data/osm/guernsey-jersey-latest.osm.pbf > out.txt &

create schema guernsey_jersey;
alter table planet_osm_point set schema guernsey_jersey;
alter table planet_osm_line set schema guernsey_jersey;
alter table planet_osm_polygon set schema guernsey_jersey;
alter table planet_osm_roads set schema guernsey_jersey;

wget -r -np -nH -A "*-latest.osm.pbf" https://download.geofabrik.de/europe/germany/ 
*/

select distinct iso3, pays from camps.camps6 c 
order by iso3;

-- df -H 
-- /dev/mapper/externe-data           633G    349G  253G  58% /data

update camps.camps6  c set ecole_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college') ) and c.iso3 in ('AUT') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('AUT') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id and ecole_hors_camp_distance_km is null;

select c.unique_id, c.nom from camps.camps6  c where c.iso3 in ('AUT');

select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('AUT') and c.point3857 is not null
	group by c.unique_id
	
select c.unique_id ,   'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) 
	and c.iso3 in ('AUT') and c.point3857 is not null

select osm_id from public.osm_polygon osm 
alter view public.osm_polygon column osm_id type float 

drop view public.osm_polygon;
-- correction du type de population
create or replace VIEW  public.osm_polygon AS
            SEsLECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.austria.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
                                    ')
    AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ;

 ---
/* 'guernsey-jersey'
'isle-of-man'
'ireland-and-northern-ireland'
england'
scotland'
wales'*/

create or replace VIEW  public.osm_point_uk AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.england.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.scotland.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )			
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.wales.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.ireland_and_northern_ireland.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.isle_of_man.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

drop VIEW  public.osm_polygon_uk;     

create or replace VIEW  public.osm_polygon_uk AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.isle_of_man.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.ireland_and_northern_ireland.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.wales.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.scotland.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.england.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						
				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

--- Germany
           /*
baden_wuerttemberg
bayern
berlin
brandenburg
bremen
hamburg
hessen
mecklenburg_vorpommern
niedersachsen
nordrhein_westfalen
rheinland_pfalz
saarland
sachsen_anhalt
sachsen
schleswig_holstein
thueringen
*/
           
create or replace VIEW  public.osm_point_germany AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.baden_wuerttemberg.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bayern.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )			
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.berlin.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.brandenburg.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bremen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.hamburg.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.hessen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.mecklenburg_vorpommern.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.niedersachsen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.nordrhein_westfalen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.rheinland_pfalz.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.saarland.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.sachsen_anhalt.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.sachsen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.schleswig_holstein.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.thueringen.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

select * from  public.osm_point_germany limit 2; 

drop VIEW  public.osm_polygon_germany;     

create or replace VIEW  public.osm_polygon_germany AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.baden_wuerttemberg.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bayern.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.berlin.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.brandenburg.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.bremen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.hamburg.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )						
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.hessen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.mecklenburg_vorpommern.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.niedersachsen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.nordrhein_westfalen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.rheinland_pfalz.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.saarland.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.sachsen_anhalt.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.sachsen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.schleswig_holstein.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.thueringen.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

select * from  public.osm_polygon_germany opg limit 2; 
select * from  public.osm_point_germany opg limit 2; 

--- Portugal
           
create or replace VIEW  public.osm_point_portugal AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.portugal.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 

						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.azores.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

create or replace VIEW  public.osm_polygon_portugal AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.portugal.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null          
           				UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.azores.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

create or replace VIEW  public.osm_point AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.austria.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
                                    ')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ;
           
create or replace VIEW  public.osm_polygon AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.austria.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
                                    ')
    AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 
   
--------------------------------------------------------------------------------------------------
-- exportS le 11.10.2024
--------------------------------------------------------------------------------------------------
-- vérifier les valeurs OSM
select unique_id, nom, iso3, pays, 
localisation_qualite, camp_latitude, camp_longitude, 
pays_population , derniere_date_info ,
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
--ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
where iso3 = 'AUT' -- DEU
order by pays ;

-- vérifier les long/lat des camps dont les coordonnées ont été retrouvées
select unique_id, geom, nom, iso3, pays, 
localisation_qualite, camp_latitude, camp_longitude, 
pays_population , derniere_date_info ,
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
where unique_id in (587, 1543)
order by pays ;
-- merde je ne les ai pas.
-- le 25.11.2024 : c'est bon 





update camps.camps6  c set ecole_hors_camp_distance_km = round((dkm/ 1000.0)::numeric, 1)
from (
	select unique_id , min(dkm) as dkm from (
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'point'
	from public.osm_point osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college') ) and c.iso3 in ('AUT') and c.point3857 is not null
	group by c.unique_id
	union 
	(
	select c.unique_id , min(st_distance(osm.way, c.point3857)) as dkm, 'polygon'
	from public.osm_polygon osm , camps.camps6  c
	where (amenity in ('school', 'college') or building in ('school', 'college')) and c.iso3 in ('AUT') and c.point3857 is not null
	group by c.unique_id
	)
	) as u 
	group by unique_id
) as k 
where k.unique_id = c.unique_id ;


	
select unique_id, id, nom, doublon,  bdd_source,
localisation_qualite, camp_latitude, camp_longitude, 
iso3, pays, pays_population , derniere_date_info ,
"ouverture/premiere_date",
fermeture_date,
derniere_date_info,
actif_dernieres_infos,
-- url_maps, 
camp_adresse, camp_code_postal, camp_commune, 
-- ville_proche_nom, ville_proche_population, 
prison, type_camp, 
-- eurostat_nuts_code_2016_level3, eurostat_nuts_code_2021_level3, 
degurba, horsdburba, 
ville_proche_nom , distance_ville_proche, ville_proche_population , "ville_proche_code postal",
eurostat_name_ascii_2016, eurostat_pop_2019,
infrastructure, climat, zone, occupation_du_sol, 
-- capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
--mairie_temps_pied, atm_temps_pied, , hopital_temps_voiture, pharmacie_temps_pied, medecin_presence, transports_publics_camp_regularite, 
--transports_publics_ville_proche_regularite, arret_bus_temps, gare_temps, medecin_clinique_hors_camp_temps, dentiste_hors_camp_temps, 
-- eurostat_computed_gisco_id, eurostat_computed_city_code, eurostat_computed_fua_code, eurostat_nuts_code_2016, eurostat_nsi_code_2016, 
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
order by pays ;
-- 2024.10.08_camp6_extractionSimple.csv
-- 2024.10.10_camp6_extractionSimple.csv
-- 2024.10.14_camp6_extractionSimple.csv

select unique_id, nom_unique, 
-- doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, 
iso3, pays, pays_population , 
-- derniere_date_info , actif_dernieres_infos,
-- "ouverture/premiere_date", fermeture_date, 
-- camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
-- horsdburba, 
-- ville_proche_nom , distance_ville_proche, "ville_proche_code postal",
ville_proche_population , 
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
-- climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, 
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
where  iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
--and coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) is null
order by pays ;
-- Illegalen Barakken Immigration Detention Facility (Curaçao)
-- 1084



------------------------------------------------------------------
--- decembre 2024
-- mise à jour infrastructure avec trois nouveaux indicateurs
-- infrastructure_norm	infrastructure_avant_conversion	infrastructure_solidite	infrastructure_confort
------------------------------------------------------------------
select distinct infrastructure, count(*) as decompte
from camps6
group by infrastructure
order by count(*) desc;

alter table camps.camps6 add column infrastructure_norm text;
alter table camps.camps6 add column infrastructure_avant_conversion text;
alter table camps.camps6 add column infrastructure_solidite int;
alter table camps.camps6 add column infrastructure_confort int;



update camps.camps6 c 
set infrastructure_norm = inf.infrastructure_norm , 
	infrastructure_avant_conversion = inf.infrastructure_avant_conversion,
	infrastructure_solidite = inf.infrastructure_solidite,
	infrastructure_confort = inf.infrastructure_confort
from public.infrastructure_nettoye inf
where inf.infrastructure = c.infrastructure ;
--1494

select distinct infrastructure 
from camps.camps6 where infrastructure_norm = 'inconnu' ;


select distinct infrastructure_norm, count(*) as decompte
from camps6
group by infrastructure_norm
order by  count(*) desc;

select distinct infrastructure, '|'||infrastructure_norm||'|' from public.infrastructure_nettoye inf
where infrastructure_norm like 'dur ';
-- dur / doute	|dur |
-- noter l'espace après le dur
update public.infrastructure_nettoye inf
set infrastructure_norm = 'dur' where infrastructure='dur / doute'; 

update camps.camps6 c 
set infrastructure_norm = 'dur',
	infrastructure_solidite = 4
where c.infrastructure = 'dur / doute';--27



select count(*), infrastructure_norm
from camps.camps6 c
group by infrastructure_norm;
-- remplacer inconnu par NULL
update camps.camps6 c  set infrastructure_norm = null
where infrastructure_norm='inconnu'; --163


select count(*), infrastructure_avant_conversion
from camps.camps6 c
group by infrastructure_avant_conversion;

update camps.camps6 c  set infrastructure_avant_conversion = 'pas de conversion'
where infrastructure_avant_conversion=''; -- 1433
update camps.camps6 c  set infrastructure_avant_conversion = 'pas de conversion'
where infrastructure_avant_conversion is null ;--297

alter table camps.camps7 add column infrastructure_norm text;
alter table camps.camps7 add column infrastructure_avant_conversion text;
alter table camps.camps7 add column infrastructure_solidite int;
alter table camps.camps7 add column infrastructure_confort int;

update camps.camps7 c7 set  
	infrastructure_norm=c6.infrastructure_norm, 
	infrastructure_avant_conversion=c6.infrastructure_avant_conversion,
	infrastructure_solidite=c6.infrastructure_solidite,
	infrastructure_confort=c6.infrastructure_confort
from camps.camps6 c6
where c6.unique_id = c7.unique_id;

select * from camps6 
where degurba  is null
and iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier');

select nom, count(*), array_agg(c.unique_id) , array_agg(c.doublon) , array_agg(c.camp_adresse)
from camps6 c 
where  doublon='Non' and point3857 is not null
group by nom
having count(*) > 1;

----------------------------------------
-- capacite
----------------------------------------


select nom, camp_latitude , camp_longitude , camp_adresse , 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null)))))))
from camps6 c 
where c.unique_id in (1341,1342);


select capacite_2022::int  from camps6 c ;

update camps.camps7 c set capacite_2022 = null where capacite_2022 = 'pas de données'; -- 117
update camps.camps7 c set capacite_2022 = null where capacite_2022 = 'pas_de_donnees'; -- 1
update camps.camps7 c set capacite_2022 = null where capacite_2022 like '%non_pertinent%' ;-- 24 
update camps.camps7 c set capacite_2022 = null,capacite_2023=1625  where capacite_2022 like '%1625 (2023)%' ;-- 1 
update camps.camps7 c set capacite_2022 = null where capacite_2022 like '%NP - closing procedure en avril 2021%' ;-- 1 

update camps.camps7 c set capacite_2017 = 10 where capacite_2017='10 (2016)' ; --1 
update camps.camps7 c set capacite_2017 = 3000 where capacite_2017 like '%3000?%' ; --1 
update camps.camps7 c set capacite_2017 = 4000 where capacite_2017 like '%4000?%' ; --1 

select capacite_2017::int  from camps.camps7 c ;

select * from camps.camps7 c where capacite_2022 like '%pas_de_donnees%' ;
-- 30 / Steenokkeerzeel (Bruxelles) 127 bis - Centre administratif national pour la transmigration

---------------------------------------
-- nom_unique
----------------------------------------
select newnom, array_agg(unique_id) from 
(
	select c.nom||' - '||unique_id%10 as newnom, unique_id, unique_id%10
	from camps.camps6 c , (
		select nom, count(*), array_agg(c.unique_id) , array_agg(c.doublon) , array_agg(c.camp_adresse)
		from camps.camps6 c 
		where  doublon='Non' and point3857 is not null
		group by nom
		having count(*) > 1) as k 
	where k.nom = c.nom
	order by k.nom
) as q 
group by newnom
having count(*) > 1;

alter table camps.camps7 add column nom_unique text;

update camps.camps7 c set nom_unique = q.newnom
from 
(
	select c.nom||' - '||unique_id%10 as newnom, unique_id, unique_id%10
	from camps.camps7 c , (
		select nom, count(*), array_agg(c.unique_id) , array_agg(c.doublon) , array_agg(c.camp_adresse)
		from camps.camps7 c 
		where  doublon='Non' and point3857 is not null
		group by nom
		having count(*) > 1) as k 
	where k.nom = c.nom
	order by k.nom
) as q 
where q.unique_id = c.unique_id;--104

select nom, nom_unique, unique_id  from camps.camps7 where nom like 'MARSEILLE%' order by unique_id ;
update camps.camps7 c set nom_unique = 'MARSEILLE - CADA - 2' where unique_id = 1188;
update camps.camps7 c set nom_unique = 'MARSEILLE - CADA - 3' where unique_id = 1189;
update camps.camps7 c set nom_unique = nom where nom_unique is null;


select nom_unique, count(*), array_agg(c.unique_id) , array_agg(c.doublon) , array_agg(c.camp_adresse)
		from camps.camps7 c 
		where  doublon='Non' and point3857 is not null
		group by nom_unique
		having count(*) > 1;

---------------------------------------
-- valeurs OSM exceptionnelles
----------------------------------------
	
-- Corriger des valeurs qui sont des valeurs exceptionnelles dues à un manque de données OSM
-- pas fait sur le serveur 
update camps6 c 
set mairie_distance = null,atm_distance = null, hopital_distance=null, pharmacie_distance= null, 
arret_bus_distance_km = null, gare_distance_km=null,medecin_clinique_hors_camp_distance_km = null,
dentiste_hors_camp_distance_km = null,ecole_hors_camp_distance_km=null,  poste_hors_camp_distance_km=null
where mairie_distance > 500; --27

---------------------------------------------------------------
-- Extraction des données 5/12/2024
---------------------------------------------------------------

	
	
select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , 
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom , distance_ville_proche, "ville_proche_code postal",
ville_proche_population , 
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, 
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
geom
from camps.camps6 c 
 where  
-- unique_id in(192, 452, 1552, 454, 399, 879, 694, 740 );
iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )-- schengen, mais il manque 'LVA', 'ROU', 'BGR', 'HRV' 
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
--and coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) is null
order by pays ;
-- extract le 05/12/2024


select unique_id, nom_unique, 
-- doublon,  bdd_source, localisation_qualite, 
-- camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , 
-- derniere_date_info , actif_dernieres_infos, "ouverture/premiere_date", fermeture_date, 
-- camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
-- capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
-- ville_proche_nom , distance_ville_proche, "ville_proche_code postal",
ville_proche_population , 
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, 
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
-- geom
from camps.camps6 c 
 where  
unique_id in (686, 788);
-- (192, 452, 1552, 454, 399, 879, 694, 740 );
-- iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
-- and point3857 is not null and doublon='Non' 
-- and localisation_qualite in ('vérifiée', 'quartier')
--and coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) is null
order by pays ;


select distinct iso3, pays , pays_population, count(*), count(*)/pays_population * 1000000
from camps6 c 
where 
iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
group by iso3, pays ,pays_population
order by count(*)/pays_population * 1000000;

select distinct pays, iso3, *
from camps6 c 
where 
iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and iso3 = 'DNK';
group by pays, iso3;
-- 945 camps

and degurba is null
and clc_majoritaire_23_mixte is null -- 865	1098.0	Illegalen Barakken Immigration Detention Facility (Curaçao)



select distinct iso3, pays , pays_population, count(*), count(*)/pays_population * 1000000 as rang
from camps6 c 
where 
iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
group by iso3, pays ,pays_population
order by count(*)/pays_population * 1000000;

-- GBR United Kingdom of Great Britain and Northern Ireland
-- TUR Turkey
-- BIH Bosnia and Herzegovina
-- IRL Ireland
-- CYP	Cyprus

select c.unique_id , c.actif_dernieres_infos, c.nom, c.degurba, c.mairie_distance , c.arret_bus_distance_km ,c.clc_majoritaire_23_mixte, c.distance_24_zones_agricoles_heterogenes 
from camps6 c 
where  
iso3 = 'IRL';

select c.iso3, c.pays , c.unique_id , c.nom, c.horsdburba, c.degurba, c.mairie_distance , c.arret_bus_distance_km ,c.clc_majoritaire_23_mixte, c.distance_24_zones_agricoles_heterogenes 
from camps6 c ,
(select distinct iso3, pays , min(c.unique_id) as exemplaire
	from camps6 c 
	where 
	iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
	and point3857 is not null and doublon='Non' 
	and localisation_qualite in ('vérifiée', 'quartier')
	group by iso3, pays 
) as  k 
where c.unique_id = k.exemplaire
order by horsdburba , clc_majoritaire_23_mixte , c.iso3; 

-- croatie, lettonie, roumanie, bulgarie
select * from camps6 c where c.pays like '%Romania%';-- ROU
select * from camps6 c where c.pays like '%Bulgaria%';-- BGR
select * from camps6 c where c.pays ilike '%Croatia%'; -- HRV
-- 'LVA', 'ROU', 'BGR', 'HRV'
select distinct pays, iso3 from camps6 c order by pays;

select unique_id , nom, c.bdd_source , c.camp_adresse , iso3 , pays, camp_latitude , camp_longitude  from camps6 c 
	where unique_id in (879, 1007);
	-- erreur de longitude sur 879 (angleterre et pas NL)


	
select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , 
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom , distance_ville_proche, "ville_proche_code postal",
ville_proche_population , 
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, 
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen 
geom
from camps.camps6 c 
 where  
-- unique_id in(192, 452, 1552, 454, 399, 879, 694, 740 );
-- iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC' )
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
--and coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) is null
order by pays ;

select distinct actif_dernieres_infos, count(*) 
from camps.camps6 c 
where  point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
group by actif_dernieres_infos;
-- 1153 camps en oui. non : 134;  doute : 66

select  c.clc_majoritaire_23_mixte , count(*)
from camps.camps6 c
where point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier') 
and actif_dernieres_infos='oui'
and iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
group by clc_majoritaire_23_mixte 
order by clc_majoritaire_23_mixte;

select * from camps.camps6 c
where point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier') 
--and actif_dernieres_infos='oui'
--and iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
--and clc_majoritaire_23_mixte is not null;

----------------------------------------------------------------------------------------
-- Analyse sur la version camps7
-- distance et population des villes proches corrigées
-----------------------------------------------------------------------------------------



select distinct pays, iso3 from camps.camps7 order by pays;
---------------------------------------
-- valeurs OSM exceptionnelles
----------------------------------------
	
-- Corriger des valeurs qui sont des valeurs exceptionnelles dues à un manque de données OSM
--  fait sur le serveur 
update camps.camps6 c 
set mairie_distance = null,atm_distance = null, hopital_distance=null, pharmacie_distance= null, 
arret_bus_distance_km = null, gare_distance_km=null,medecin_clinique_hors_camp_distance_km = null,
dentiste_hors_camp_distance_km = null,ecole_hors_camp_distance_km=null,  poste_hors_camp_distance_km=null
where mairie_distance > 500; --27

update camps.camps7 c 
set mairie_distance = null,atm_distance = null, hopital_distance=null, pharmacie_distance= null, 
arret_bus_distance_km = null, gare_distance_km=null,medecin_clinique_hors_camp_distance_km = null,
dentiste_hors_camp_distance_km = null,ecole_hors_camp_distance_km=null,  poste_hors_camp_distance_km=null
where mairie_distance > 500;

select unique_id, nom_court, iso3, pays, mairie_distance
from camps.camps6 c
where mairie_distance is null and geom is not null
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
order by pays;
-- antilles françaises (FRA) et canaries espagnoles (ESP)

-- liste des distances OSM à refaire antilles françaises (FRA)
select array_agg(''''||unique_id||'''')
from camps.camps6 c
where mairie_distance is null and geom is not null and iso3 = 'FRA';
-- ('196','197','198','201','202','116','214','203','115','102','193','208','206','195','194','210','191','192','207')
-- liste des distances OSM à refaire canaries espagnoles (ESP)
select array_agg(''''||unique_id||'''')
from camps.camps6 c
where mairie_distance is null and geom is not null and iso3 = 'ESP';
-- ('451','741','597','453','457','743','452')

select unique_id, nom_court, iso3, pays, mairie_distance
from camps.camps6 c
where mairie_distance > 500 and geom is not null and iso3 = 'ESP';

select unique_id, nom_court, iso3, pays, 
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km
from camps.camps7 c
where unique_id in ('451','741','597','453','457','743','452') and geom is not null and iso3 = 'ESP';

select unique_id, nom_court, iso3, pays, 
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km
from camps.camps7 c
where unique_id in ('196','197','198','201','202','116','214','203','115','102','193','208','206','195','194','210','191','192','207') 
and geom is not null and iso3 = 'FRA';

--196	Nouméa (Aéroport de - Nouvelle Calédonie)
--202	Païta (Nouvelle-Calédonie)
--210	Saint-Martin

update camps.camps7 c 
set mairie_distance = null,atm_distance = null, hopital_distance=null, pharmacie_distance= null, 
arret_bus_distance_km = null, gare_distance_km=null,medecin_clinique_hors_camp_distance_km = null,
dentiste_hors_camp_distance_km = null,ecole_hors_camp_distance_km=null,  poste_hors_camp_distance_km=null
where unique_id in ('196', '202', '210');


--- Canaries : canary_islands
create or replace VIEW  public.osm_point_canary AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.canary_islands.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
							')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

create or replace VIEW  public.osm_polygon_canary AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.canary_islands.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 
			')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

--- DOMTOM France : 'guadeloupe', 'guyanne', 'martinique', 'mayotte', 'reunion'
    
create or replace VIEW  public.osm_point_dom_france AS
            SELECT osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.guadeloupe.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null 

						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.guyane.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )	

						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.martinique.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.mayotte.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
						UNION (
							select osm_id, way, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.reunion.planet_osm_point a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''college'', ''community_centre'', ''social_centre'', ''bureau_de_change'', ''language_school'', ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'', ''hospital'', ''school'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )
				')
            AS t1(osm_id int8, way geometry, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

create or replace VIEW  public.osm_polygon_dom_france AS
            SELECT osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
            FROM dblink('dbname=osm user=postgres password=****** options=-csearch_path=',
                        'select osm_id, way, name, admin_level, population, aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.guadeloupe.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null          
           				UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.guyane.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )

					UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.martinique.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )

					UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.mayotte.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )

					UNION (
							select osm_id, way, name, admin_level, replace(population, '' '', ''''), aeroway,amenity,boundary,building,highway,landuse,leisure,man_made,military,office,power,public_transport,railway,shop,waterway 
                            from osm.reunion.planet_osm_polygon a 
                            where amenity in (''atm'',''bus_station'',''clinic'',''dentist'',''doctors'',''drinking_water'',''hospital'',''pharmacy'',''recycling'',''townhall'',''water_point'', ''post_box'', ''post_office'', ''school'', ''childcare'', ''kindergarten'', ''college'', ''community_centre'',  ''post_office'', ''clinic'',  ''internet_cafe'')
									or boundary in (''administrative'',''hazard'',''national_park'',''protected_area'')
									or aeroway=''aerodrome''
									or building in (''train_station'',''healthcare'', ''hospital'', ''clinic'', ''townhall'', ''school'', ''college'', ''kindergarten'', ''childcare'')
									or landuse=''quarry''
									or highway in (''bus_stop'',''motorway'',''trunk'')
									or leisure in (''nature_reserve'', ''shooting_ground'')
									or man_made in (''wastewater_plant'', ''man_made=water_tap'')
									or military=''danger_area''
									or office=''lawyer''
									or power=''line''
									or public_transport in (''platform'', ''station'')
									or railway in (''halt'',''platform'',''rail'',''station'')
									or shop in (''chemist'', ''medical_supply'')
									or waterway=''water_point''
									or population is not null )


				')
            AS t1(osm_id int8, way geometry, name text, admin_level int, population text, aeroway text,amenity text,boundary text,building text,highway text,landuse text,leisure text,man_made text,military text,office text,power text,public_transport text,railway text,shop text,waterway text) ; 

------------------------------
-- Arnhem aux Pays-Bas (pas fait sur serveur)
------------------------------

select * from camps.camps7 c where c.unique_id = '879';
select * from camps.camps7 c where c.unique_id = '878';

-- 1334	879	1112.0	Arnheim New Quay Emergency Shelter	Arnheim New Quay ES	Non	site officiel du gouvernement	recherches personnelles	https://www.coa.nl/nl/locatie/arnhem-nieuwe-kade	NLD	Netherlands	17344874		Non pertinent		2023	oui	quartier	50.414939838612	-5.07373155110458		Albany Rd, Newquay TR7 1DD, Royaume-Uni			Plymouth		404849.0	non	ouvert	doute									726																																				310.2		310.5		313.6		313.4					310.7		102.5		310.2		314.0																340.0																																																																																																															UK_E06000052		UK516C1	UKK30	E06000052	Cornwall	565968	106.0			2.0	112	11	11.0	3.0	27.0	17.0	6.0	33.0			POINT (-5.07373155110458 50.414939838612)	POINT (-564805.2126907293 6518448.646822049)	POINT (3258241.7986291638 3143580.0812749956)	112	309.0	loin_interne	POINT (-5.07373155110458 50.414939838612)	false	309.9	310.0	112	Arnheim New Quay Emergency Shelter		pas de conversion		
update camps.camps7 set camp_latitude ='51.97', camp_longitude ='5.92', camp_adresse = null where unique_id ='879';
-- garde le CLC à 112
update camps.camps7 c set ville_proche_nom = 'Arnhem', ville_proche_population = 427643, distance_ville_proche = 5, 
eurostat_computed_fua_code = 'NL009L3', 
eurostat_computed_gisco_id = 'NL_GM0202', eurostat_nuts_code_2016 = 'NL226', eurostat_nsi_code_2016 = 'GM0202',
eurostat_name_ascii_2016 = 'Arnhem', eurostat_pop_2019 = 161368, degurba = 1,
geom = st_setsrid(st_makepoint(camp_longitude, camp_latitude), 4326)
where c.unique_id ='879' ;

update camps.camps7 c set 
point3857 = st_setsrid(st_transform(c.geom, 3857), 3857),
point3035 = st_setsrid(st_transform(c.geom, 3035), 3035),
point4258 = st_setsrid(st_transform(c.geom, 4258), 4258),
distanceschengenkm = c2.distanceschengenkm ,
eloignementschengen = c2.eloignementschengen ,
distance_13_mines_decharges_chantiers = c2.distance_13_mines_decharges_chantiers ,
distance_124_aeroport = c2.distance_124_aeroport ,
distance_123_zones_portuaires = c2.distance_123_zones_portuaires ,
distance_122_reseaux_routiers = c2.distance_122_reseaux_routiers ,
distance_24_zones_agricoles_heterogenes = c2.distance_24_zones_agricoles_heterogenes ,
distance_41_zones_humides_interieures = c2.distance_41_zones_humides_interieures ,
mairie_distance = c2.mairie_distance,
atm_distance  = c2.atm_distance,
hopital_distance  = c2.hopital_distance,
pharmacie_distance  = c2.pharmacie_distance,
arret_bus_distance_km  = c2.arret_bus_distance_km,
gare_distance_km  = c2.gare_distance_km,
poste_hors_camp_distance_km  = c2.poste_hors_camp_distance_km,
ecole_hors_camp_distance_km  = c2.ecole_hors_camp_distance_km,
medecin_clinique_hors_camp_distance_km = c2.medecin_clinique_hors_camp_distance_km,
dentiste_hors_camp_distance_km = c2.dentiste_hors_camp_distance_km
from camps.camps7 c2
where c.unique_id ='879' and c2.unique_id = '878';


-------------------------------
-- espace Schengen remis à jour
-- (pas fait sur le serveur)
-------------------------------
-- la colone Espace_Schengen n'existe que sur le serveur
alter table demographie.ne_10m_admin_0_countries add column Espace_Schengen boolean;
update demographie.ne_10m_admin_0_countries set Espace_Schengen = false;
comment on column demographie.ne_10m_admin_0_countries.Espace_Schengen is 'Le Pays fait partie de l''Espace de Schengen en Europe';

update demographie.ne_10m_admin_0_countries set Espace_Schengen = true 
where adm0_a3 in ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' );--23
-- 27

select admin,  adm0_a3 from demographie.ne_10m_admin_0_countries ne where ne.Espace_Schengen is true order by admin;
-- https://www.touteleurope.eu/fonctionnement-de-l-ue/le-fonctionnement-de-l-espace-schengen/
alter table demographie.ne_10m_admin_0_countries add column poly3857 geometry;
update demographie.ne_10m_admin_0_countries set poly3857 = st_setsrid(st_transform(wkb_geometry, 3857),3857) where Espace_Schengen is true;

update camps.camps7  c set distanceSchengenkm = round(k.min_d/1000)
from (
	select c.unique_id, min(st_distance(c.point3857, st_boundary(ne.poly3857))) as min_d
	from camps.camps7 c, demographie.ne_10m_admin_0_countries ne
	where 
	-- ne.Espace_Schengen is true and c.distanceSchengenkm = 0
	ne.adm0_a3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
	group by c.unique_id
) as k where k.unique_id = c.unique_id ;
-- 1791 interne

select unique_id, nom, pays, distanceSchengenkm  from camps.camps6 where pays = 'France'
-- distanceSchengenkm > 30;

update camps.camps7  c set eloignementSchengen = 'loin_interne' 
where distanceSchengenkm > 30 and 
 	iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' );
-- 725 / 714

update camps.camps7  c set eloignementSchengen = 'proche_interne' 
where distanceSchengenkm <= 30 and 
 	iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' );
-- 619 / 630

update camps.camps7  c set eloignementSchengen = 'loin_externe' 
where distanceSchengenkm > 30 and 
 	iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' );
-- 410 / 395

update camps.camps7  c set eloignementSchengen = 'proche_externe' 
where distanceSchengenkm <= 30 and 
 	iso3 not in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 
	'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 
	'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' );
-- 27 / 42

------------------
--- degurba incorrect en grèce (zones portuaires)
------------------

-- fait sur local, et à faire sur server
update camps.camps7 c
set degurba = 2
where unique_id  in ('280', '281', '306') 
and nom_court in ('Igoumenitsa (Police Station)', 'Igoumenitsa (Police Station)', 'Lesbos Harbor');

--------------------------------------------
-- Ajouter une nouvelle variable surface des pays
-----------------------------------------------
-- à faire sur server

alter table camps.camps7 add column pays_surfacekm2 float;

select st_area(ne.wkb_geometry, true)/(1000000), adm0_a3, admin from demographie.ne_10m_admin_0_countries ne;

update camps.camps7 c set pays_surfacekm2= round(st_area(ne.wkb_geometry, true)/(1000000))
from demographie.ne_10m_admin_0_countries ne
where ne.adm0_a3 = c.iso3;
-- 1788

select pays, iso3, * from camps.camps7 where pays_population is null;
-- Western Sahara ESH (1)
-- Kosovo UNK(2)

select st_area(ne.wkb_geometry, true)/(1000000), adm0_a3, admin , pop_year , pop_est 
from demographie.ne_10m_admin_0_countries ne
where admin in ('Western Sahara', 'Kosovo'); 

update  camps.camps7 c 
	set pays_surfacekm2= round(st_area(w.wkb_geometry, true)/(1000000)),
from demographie.ne_10m_admin_0_countries w 
where pays_surfacekm2 is null and (w.admin ilike c.pays ); -- 2

update  camps.camps7 c 
	set pays_population = pop_est
from demographie.ne_10m_admin_0_countries w 
where pays_population is null and (w.admin ilike c.pays ); -- 1 pour le Western Sahara 

--------------------------------------------
-- Ajouter une nouvelle variable surface des communes où est implanté le camps
-----------------------------------------------

-- sera null sur Belarus, Bosnie, et Turkey
alter table camps.camps7 add column camps_commune_surfacekm2 float;

update  camps.camps7 c 
	set camps_commune_surfacekm2= w.area_km2 
from demographie.eurostat_lau_2020 w 
where w.gisco_id = c.eurostat_computed_gisco_id ; -- 2

update  camps.camps7 c 
	set camps_commune_surfacekm2= w.area_km2 
from demographie.eurostat_lau_2019 w 
where camps_commune_surfacekm2 is null and w.gisco_id = c.eurostat_computed_gisco_id ;
-- 2

select unique_id, nom_court, pays from camps.camps7 c where camps_commune_surfacekm2 is null 
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
order by pays; -- 38

----------------------------------------------------------------------------------------------
	
select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , pays_surfacekm2,
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom ,  "ville_proche_code postal",
ville_proche_population , distance_ville_proche, 
eurostat_computed_fua_code, eurostat_computed_gisco_id, eurostat_name_ascii_2016, eurostat_pop_2019, camps_commune_surfacekm2,
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, clc_majoritaire_13_mixte,
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen , 
geom
from camps.camps7 c 
 where  true
-- unique_id in(192, 452, 1552, 454, 399, 879, 694, 740 );
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
order by pays ; -- 1067 / 1153 / 1791
-- Extraction pour Louis le 05/01 (1791 sans filtre puis 1068 avec)
-- Extraction pour Louis le 06/01 (1791 sans filtre puis 1067 avec)

select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , pays_surfacekm2,
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom ,  "ville_proche_code postal",
ville_proche_population , distance_ville_proche, 
eurostat_computed_fua_code, eurostat_computed_gisco_id, eurostat_name_ascii_2016, eurostat_pop_2019, camps_commune_surfacekm2,
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, clc_majoritaire_13_mixte,
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen , 
geom
from camps.camps7 c 
 where  true
-- unique_id in(192, 452, 1552, 454, 399, 879, 694, 740 );
 and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'MNE'))
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
and derniere_date_info::int>= 2018 
order by pays ; -- 997 / 1791
-- Extraction pour Louis le 09/01 (1791 sans filtre puis 997 avec) , 'BLR'
-- Extraction pour Louis le 09/01 (1791 sans filtre puis 994 avec) et SANS 'BLR'

select unique_id, nom_court , iso3, 
localisation_qualite, actif_dernieres_infos, derniere_date_info, clc_majoritaire_13_mixte , eurostat_pop_2019 , camps_commune_surfacekm2 
from camps.camps7 c 
where unique_id in ('172', '98', '170', '165', '97', '168', '189', '190', '167', '171', '161', '169');
-- 98, 168

select unique_id, nom_court , iso3, 
localisation_qualite, actif_dernieres_infos, derniere_date_info, clc_majoritaire_13_mixte , eurostat_pop_2019 , camps_commune_surfacekm2 
from camps.camps7 c 
where unique_id in ('202', '196', '210', '865');


select distinct  derniere_date_info from camps.camps7 c
--pas de données
--2019 (2022)
--2018 (2022)
--pas_de_donnees
update camps.camps7 c set derniere_date_info = null where derniere_date_info in ('pas de données', 'pas_de_donnees');
-- 18
select * from camps.camps7 c where derniere_date_info in ('2019 (2022)', '2018 (2022)');
-- 2 camps : 515 en turquie, 563 en GBR
update camps.camps7 c set derniere_date_info = 2018 where derniere_date_info in ('2019 (2022)', '2018 (2022)');

-- encore une erreur
-- les CLC en Biolrussie BLR ne peuvent pas être renseignée

select count(*)
from camps.camps7 c; --1791

select count(*)
from camps.camps7_local ; --1791

select clocal.unique_id, c.iso3,
c.ville_proche_nom , c."ville_proche_code postal", c.ville_proche_population , c.distance_ville_proche,
clocal.ville_proche_nom , clocal."ville_proche_code postal", clocal.ville_proche_population , clocal.distance_ville_proche,
c.eurostat_computed_fua_code, clocal.eurostat_computed_fua_code
from camps.camps7_local clocal, camps.camps7 c
where clocal.unique_id=c.unique_id and c.geom is not null
and clocal.distance_ville_proche != c.distance_ville_proche
order by iso3;
-- conclusion : la version serveur est meilleure, au moins pour les eurostat_computed_fua_code

select c.unique_id, c.nom_court , c.iso3, 
c.ville_proche_nom , c."ville_proche_code postal", c.ville_proche_population , c.distance_ville_proche,
c.eurostat_computed_fua_code, degurba
from camps.camps7 c
where  c.geom is not null and iso3 = 'GRC';


select clocal.unique_id, c.iso3, c.eurostat_pop_2019, c.camps_commune_surfacekm2 
c.ville_proche_nom , c."ville_proche_code postal", c.ville_proche_population , c.distance_ville_proche,
clocal.eurostat_pop_2019,
clocal.ville_proche_nom , clocal."ville_proche_code postal", clocal.ville_proche_population , clocal.distance_ville_proche,
c.eurostat_computed_fua_code, clocal.eurostat_computed_fua_code
from camps.camps7_local clocal, camps.camps7 c
where clocal.unique_id=c.unique_id and c.geom is not null
and clocal.eloignementschengen != c.eloignementschengen
order by iso3;
-- refaire eloignementschengen avec le bon schegen 

select unique_id, count(*) from camps.camps7 c 
group by unique_id
having  count(*) > 1;

select unique_id, nom_court , iso3, pays from camps.camps7 c 
where clc_majoritaire_13_mixte is null 
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
order by pays;
/*
 * 25	Vitebsk Pre-trial detention center	BLR	Belarus
26	Minsk Center for isolation of offenders	BLR	Belarus
670	Minsk Pre-trial detention centre	BLR	Belarus
671	Brest Pre-trial detention centre #7	BLR	Belarus
202	Païta (Nouvelle-Calédonie)	FRA	France
196	Nouméa (Aéroport de - Nouvelle Calédonie)	FRA	France
210	Saint-Martin	FRA	France
865	Curaçao Detention Facility	NLD	Netherlands
 */

-- exclure 202, 196, 210, 865 de l'analyse

select unique_id, nom_court , iso3, pays from camps.camps7 c 
where degurba is null 
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
order by pays;
-- ne pas retirer BIH TUR et BLR
-- retirer FRA NLD

select max(c.camps_commune_surfacekm2)
from camps.camps7 c 
where  (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865');

select * from camps.camps7 c where distanceschengenkm = 12315
-- ville_proche_population 12882627
-- distanceschengenkm  1709.0 12315
-- mairie_distance 57.2
-- distance_13_mines_decharges_chantiers 198.0
select * from camps.camps7 c where distanceschengenkm = 1709

select unique_id, nom_court, pays from camps.camps7 c where eloignementschengen is null 
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865');

select unique_id, nom_court, pays from camps.camps7 c where eurostat_pop_2019 is null 
and (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
order by pays;

select st_asewkt(geom), unique_id, nom_court, iso3, pays, pays_population ,camp_latitude::float, camp_longitude::float from camps.camps7 c 
where  (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR', 'BLR'))
and geom is not null
and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
and (camps_commune_surfacekm2 is null or eurostat_pop_2019 is null)
order by pays;

select distinct iso3 from camps.camps7 c 
where  (iso3 in  ('LUX', 'DEU', 'ESP', 'POL', 'FIN', 'HUN', 'EST', 'SWE', 'SVK', 'ITA', 'DNK', 'NOR', 'CZE','CHE', 'BEL' , 'NLD', 'SVN', 'MLT', 'PRT', 'LTU', 'FRA', 'AUT', 'GRC', 'LVA', 'ROU', 'BGR', 'HRV' )
or iso3 in ('HRV', 'IRL', 'ALB', 'BGR', 'CYP', 'MKD', 'ROU', 'LVA', 'SRB', 'GBR', 'BIH', 'TUR'))
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
and derniere_date_info::int>= 2018 
order by iso3 ;

select * from camps.camps7 c where iso3 = 'MNE'; --387


select c.unique_id, c.nom_unique , c.iso3, c.eurostat_pop_2019, c.camps_commune_surfacekm2 ,
c.ville_proche_nom , c."ville_proche_code postal", c.ville_proche_population , c.distance_ville_proche, c.eurostat_computed_fua_code
from  camps.camps7 c
where  c.geom is not null and doublon = 'Non' 
--and localisation_qualite in ('vérifiée', 'quartier')
--and actif_dernieres_infos = 'oui'
--and derniere_date_info::int>= 2018
and iso3 = 'BIH'
order by ville_proche_nom;

update camps.camps7 c set eurostat_computed_fua_code = 'HR001L'  where c.unique_id = 615;

select * from camps.camps7 c where c.unique_id = '694';

select * from camps.camps7 c where c.nom_court like '%694';

select iso3, pays, count(*), 'schengen' as groupUE from camps.camps7 c
where iso3 in
( 'FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL' )
group by iso3, pays, groupUE
union 
(	select iso3, pays, count(*), 'hors schengen' as groupUE from camps.camps7 c
	where iso3 in
	('GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR' ) 
	group by iso3, pays, groupUE
)
union 
(	select iso3, pays, count(*), 'hors analyse' as groupUE from camps.camps7 c
	where iso3 not in
	('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR' ) 
	group by iso3, pays, groupUE
)
order by groupUE desc, iso3, pays;
-- suisse, 

select iso3, count(*) from camps.camps7 c
where iso3 in
	('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR' ) 
and c.geom is not null and doublon = 'Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and derniere_date_info::int>= 2018
group by iso3
order by  iso3;

-- ISO_A3 in ('BIH', 'DZA', 'AZE', 'BLR', 'EGY', 'ESH', 'GEO', 'ISR', 'JOR', 'LBN', 'LBY', 'MAR', 'MDA', 'MRT', 'TUN', 'UKR')

select pays, iso3 from camps.camps7 c where c.pays like 'Mont%'
-- Montenegro	MNE
select pays, iso3 from camps.camps7 c where c.pays like 'Koso%'
-- Kosovo	UNK
select * from demographie.ne_10m_admin_0_countries c where c.admin like '%Iceland%'
-- Iceland ISL

select  iso3, count(*) from camps.camps7 c where c.clc_majoritaire_3 is not null
group by iso3
order by  iso3;

select  iso3, count(*) from camps.camps7 c where c.degurba is not null
group by iso3
order by  iso3;

select  iso3, count(*) from camps.camps7 c where c.eurostat_computed_fua_code is not null
group by iso3
order by  iso3;

select  iso3, count(*) from camps.camps7 c where c.eurostat_pop_2019 is not null
group by iso3
order by  iso3;


select iso3, count(*) from camps.camps7 c
where iso3 = 'BGR' 
--in 	('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR' ) 
and c.geom is not null 
and doublon = 'Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and derniere_date_info::int>= 2018
group by iso3
order by  iso3;



select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , pays_surfacekm2,
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom ,  "ville_proche_code postal",
ville_proche_population , distance_ville_proche, 
eurostat_computed_fua_code, eurostat_computed_gisco_id, eurostat_name_ascii_2016, eurostat_pop_2019, camps_commune_surfacekm2,
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, clc_majoritaire_13_mixte,
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen , 
geom
from camps.camps7 c 
 where  true
-- unique_id in(192, 452, 1552, 454, 399, 879, 694, 740 );
 and iso3 in  ('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR')
and point3857 is not null and doublon='Non' 
and localisation_qualite in ('vérifiée', 'quartier')
and actif_dernieres_infos = 'oui'
and unique_id not in ('202', '196', '210', '865')
and derniere_date_info::int>= 2018 
order by pays ; -- 997 / 1791
-- Extraction pour Louis le 16/01 (1791 sans filtre puis 997 avec) , 'BLR'
-- Extraction pour Louis le 16/01 (1791 sans filtre puis 994 avec) et SANS 'BLR'

select  iso3, pays, c.pays_population , count(*), count(*)/c.pays_population * 1000000
from camps.camps7 c 
 where  true 
 --and iso3 in ('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR')
 -- and clc_majoritaire_13_mixte is not null and iso3 != 'UKR'
 and point3857 is not null and doublon='Non' 
-- and localisation_qualite in ('vérifiée', 'quartier')
-- and actif_dernieres_infos = 'oui'
-- and unique_id not in ('202', '196', '210', '865')
-- and derniere_date_info::int>= 2018 
group by iso3, pays, c.pays_population
order by count(*)/c.pays_population asc;

select   localisation_qualite , count(*)
from camps.camps7 c 
 where  true 
 --and iso3 in ('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR')
 -- and clc_majoritaire_13_mixte is not null and iso3 != 'UKR'
 and point3857 is  not null and doublon='Non' 
-- and localisation_qualite in ('vérifiée', 'quartier')
-- and actif_dernieres_infos = 'oui'
-- and unique_id not in ('202', '196', '210', '865')
-- and derniere_date_info::int>= 2018 
 group by localisation_qualite
 
 select 79 + 1712
 
-----------------------------------------
 

select unique_id, nom_unique, 
doublon,  bdd_source, localisation_qualite, 
camp_latitude, camp_longitude, "URL_maps",
iso3, pays, pays_population , pays_surfacekm2,
derniere_date_info , actif_dernieres_infos,
"ouverture/premiere_date", fermeture_date, 
camp_adresse, camp_code_postal, camp_commune, 
type_camp, 
capacite_2017, capacite_2018, capacite_2019, capacite_2020, capacite_2021, capacite_2022, capacite_2023, effectif_2017, effectif_2018, effectif_2019, effectif_2020, effectif_2021, effectif_hommes_2022, effectif_femmes_2022, effectifs_mineurs_2022, effectif_total_2022, duree_max_2017, duree_max_2018, duree_max_2019, duree_max_2020, duree_max_2021, duree_max_2022, duree_moy_2017, duree_moy_2018, duree_moy_2019, duree_moy_2020, duree_moy_2021, duree_moy_2022, mineurs_2017, mineurs_2018, mineurs_2019, mineurs_2020, mineurs_2021, nationalite, 
coalesce(capacite_2023, coalesce(capacite_2022::int, coalesce(capacite_2021, coalesce(capacite_2020, coalesce(capacite_2019, coalesce(capacite_2018, coalesce(capacite_2017::int, null))))))) as capacite,
prison, 
degurba, 
horsdburba, 
ville_proche_nom ,  "ville_proche_code postal",
ville_proche_population , distance_ville_proche, 
eurostat_computed_fua_code, eurostat_computed_gisco_id, eurostat_name_ascii_2016, eurostat_pop_2019, camps_commune_surfacekm2,
infrastructure_norm,	infrastructure_avant_conversion,	infrastructure_solidite,	infrastructure_confort,
climat,   
mairie_distance, atm_distance, hopital_distance, pharmacie_distance, arret_bus_distance_km, gare_distance_km, 
medecin_clinique_hors_camp_distance_km, dentiste_hors_camp_distance_km,
ecole_hors_camp_distance_km, poste_hors_camp_distance_km,
clc_majoritaire_2, clc_majoritaire_3, clc_majoritaire_23_mixte, clc_majoritaire_13_mixte,
distance_13_mines_decharges_chantiers, distance_124_aeroport, distance_123_zones_portuaires, distance_122_reseaux_routiers, distance_24_zones_agricoles_heterogenes, distance_41_zones_humides_interieures, 
distanceschengenkm, eloignementschengen , 
geom
from camps.camps8 c 
 where  true
--and iso3 in  ('FRA', 'ITA', 'BEL' , 'NLD', 'LUX', 'DEU', 'ESP', 'PRT', 'SWE',  'FIN', 'DNK', 'NOR', 'POL', 'SVK', 'HUN', 'CZE', 'SVN', 'AUT', 'GRC', 'MLT', 'EST', 'LTU', 'LVA', 'ROU', 'BGR', 'HRV', 'CHE', 'ISL', 'GBR', 'IRL', 'CYP', 'ALB',  'MKD',  'SRB',  'BIH', 'MNE', 'UNK', 'TUR')
--and point3857 is not null and doublon='Non' 
--and localisation_qualite in ('vérifiée', 'quartier')
--and actif_dernieres_infos = 'oui'
--and unique_id not in ('202', '196', '210', '865')
--and derniere_date_info::int>= 2018 
order by pays ; -- 997 / 1791
-- Extraction pour Louis le 26/02 (1791 sans filtre puis 994 avec) et SANS 'BLR'

