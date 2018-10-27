-- https://github.com/fiit-pdt/hands-on/tree/2017/4-oo-sql

-- Uloha 1
-- [use fiitpdt/postgres for this excercise] Suppose the following relational schema exists, where there
-- are travel agents selling flights to some destination. A flight can have multiple services from the set {business
-- class, lunch, drinks, priority boarding, online check-in}.

-- AGENT (**a_id**, name)
-- FLIGHT (**destination**, pilot_name, a_id)
-- SERVICE (**flight**, **service**)

--
--  Transform this schema to an object version using 2 data types
--  Insert some test data
--  Write query which returns services provided on a flight to London. Results should be in 1st normal form


-- 1. riesenie
CREATE TYPE agent AS (
	id   integer,
	name text
);

CREATE TYPE flight AS (
	destination text,
	pilot_name  text,
	a_id        integer,
	service     text []
);

CREATE TABLE flights (
	agent  agent,
	flight flight
);

-- 2.riesenie

CREATE TABLE if not exists service
(
	id   integer NOT NULL,
	name text    NOT NULL,
	CONSTRAINT service_pkey PRIMARY KEY (id)
);

CREATE TABLE if not exists flight
(
	id          integer NOT NULL,
	destination text    NOT NULL,
	pilot_name  text    NOT NULL,
	services    service [],
	CONSTRAINT flight_pkey PRIMARY KEY (id)
);


INSERT INTO flights (agent, flight)
VALUES (ROW (1, 'Janko'), ROW ('USA', 'Fero', 1, '{"food", "drink", "bed"}'));

-- Query kt. vracia lety podavajuce obed:
-- Pristup ak mame objekt

SELECT *
FROM "flights" f
where (flight).services.lunch = false;

-- pristup ak mame pole
-- https://www.postgresql.org/docs/9.1/static/functions-array.html
select (flight).services
FROM flights
WHERE (flight).destination = 'london'
	and services && '{bussiness_class}' :: text [];


create type “flight” AS (
	destination text,
	pilot_name  text,
	services service
);

-- zatvorka - ak pristupujeme do stlpca, kt. je objektom
select *
from flight
where (flight).destination == 'london';

select (flight).services
from flights
where (flight).destination == 'london';

select (flight).services
from flights
where (flight).destination == 'london' and (flight).services.lunch = true;

