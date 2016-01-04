--点 POINT
--线 LINESTZRING
--面 POLYGON
--第一种
DROP TABLE gistest;

CREATE TABLE gistest (
	gid serial NOT NULL,
	NAME TEXT,
	lng NUMERIC (18, 8),
	lat NUMERIC (18, 8),
	geom geometry (POINT, 4326)
);

--第二种
DROP TABLE gistest;

CREATE TABLE gistest (
	gid serial NOT NULL,
	NAME TEXT,
	lng NUMERIC (18, 8),
	lat NUMERIC (18, 8)
);

ALTER TABLE gistest ADD COLUMN geom geometry (POINT, 4326);

--第三种
DROP TABLE gistest;

CREATE TABLE gistest (
	gid serial NOT NULL,
	NAME TEXT,
	lng NUMERIC (18, 8),
	lat NUMERIC (18, 8)
);
SELECT AddGeometryColumn ('postgres','gistest','geom',4326,'POINT',2);

--创建空间索引
create index gistest_index on gistest using gist (geom);
--插入数据

UPDATE gistest set geom=st_geomfromtext('point('||lng||' '||lat||')',4326);

INSERT INTO gistest(name,lng,lat,geom) values ('方正大厦',116.313037,40.046619,st_geomfromtext('point(116.313037 40.046619)',4326));
INSERT INTO gistest(name,lng,lat,geom) values ('百度大厦',116.307689,40.056968,st_geomfromtext('point(116.307689 40.056968)',4326));
INSERT INTO gistest(name,lng,lat,geom) values ('智学苑',116.319227,40.056236,st_geomfromtext('point(116.319227 40.056236)',4326));
--计算距离
select st_distance_sphere((select geom from gistest where name='方正大厦'),(select geom from gistest where name='智学苑'));
select st_distance_spheroid((select geom from gistest where name='方正大厦'),(select geom from gistest where name='智学苑'),'SPHEROID["WGS 84",6378137,298.257223563]');
select st_distance((select geom from gistest where name='方正大厦'),(select geom from gistest where name='智学苑'))*111194.872221777;
select st_distance((select geom from gistest where name='方正大厦'),(select geom from gistest where name='智学苑'),true);
select st_distance((select geom from gistest where name='方正大厦')::geography,(select geom from gistest where name='智学苑')::geography);
--再插入两条数据
INSERT INTO gistest(name,lng,lat,geom) values ('信息路红绿灯',116.314503,40.046698,st_geomfromtext('point(116.314503 40.046698)',4326));
INSERT INTO gistest(name,lng,lat,geom) values ('上地西路红绿灯',116.311485,40.045731,st_geomfromtext('point(116.311485 40.045731)',4326));
select st_distance_sphere((select geom from gistest where name='信息路红绿灯'),(select geom from gistest where name='上地西路红绿灯'));

--整个北京市的点
--插入一条南京市的数据
INSERT INTO gistest(name,lng,lat,geom) values ('南京市国睿大厦',118.72711,31.998248,st_geomfromtext('point(118.72711 31.998248)',4326));
select * from gistest where st_contains((select geom from city where cityname='北京市'),geom);

select * from gistest where st_within(geom,(select geom from city where cityname='北京市'));

--查询方正大厦周围500m内的点
select * from gistest where st_dwithin((select geom from gistest where name='方正大厦')::geography,geom::geography,500);

--改写方正大厦周围500m内的点，使用buffer和st_contains
select * from
    gistest
where st_contains(st_buffer((select geom from gistest where name='方正大厦')::geography,500)::geometry,geom);


--综合应用：
select
   t.name,
   ST_Distance_Sphere(t.geom,(select geom from gistest where name='方正大厦')) as distance
from (
select
    *
from
    gistest
order by geom <-> (select geom from gistest where name='方正大厦')
limit 2000
) as t
where
ST_Distance_Sphere(t.geom,(select geom from gistest where name='方正大厦'))<=500;
