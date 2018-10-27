-- WITH nam vytvori docasnu tabulku, ktoru vieme pouzit v nasledujucom dotaze - je to ine ako pohlad
-- subquerries iba vytvori pohlad na existujucu tabulku
-- pohlad na tabulku - zobrazovanie iba takych casti dat userovi, ktore zadefinujeme
-- co mozme dovolit studentovi vidiet, ake data -
-- pohlad sa tvari ako bezna tabulka, ale je to iba v pozadi nejaky predom definovany select nejakym adminom


-- WITH - znovupouzitelna tabulka - nejaky sposob optimalizacie
-- mozme pri nej robit rekurziu
with recursive t(n) AS (values (1) -- nerekurzivny vyraz / select 1
		union all -- union / union all;
		select n + 1
		from t
		where n < 10 -- recursive part
		)
select n
from t;


with recursive t(n) AS (values (1)  -- nerekurzivny vyraz / select 1, inicializacia
		union all -- union / union all;
		select n + 1
		from t -- recursive part
		)
select n
from t
limit 10;

-- pri tomto vznikaju dve tabulky -> RR-recursive | WT-working table

-- rozdiel medzi union a union all = ked dame union, bude sa snazit robit nejaku deduplikaciu
--  The UNION operator removes all duplicate rows unless the UNION ALL is used.
-- vid:
select 1, 2 as n
union
		-- union all
select 1, 2 as n;
-- union all - robi nam to deduplikaciu

-- union - znovupouzitelnost


-- Write a recursive query which returns a number and its factorial for all numbers up to 10. ☕️
--
--    ------------
--    | 0  | 1   |
--    | 1  | 1   |
--    | 2  | 2   |
--    | 3  | 6   |
--    | 4  | 24  |
--    | 5  | 120 |
--    ...
--

-- divide and conquer: 2! *3 =3!
with recursive t(n,
								 f) AS (values (0, 1) -- nonrecursive tern
		union ALL  -- union/union all
		select n + 1, f * (n + 1)
		from t -- recursive part
		)
select *
from t
limit 11;

-- Write a recursive query which returns a number and the number in Fibonacci sequence at that position for the first 20 Fibonacci numbers. ☕️☕️
--
--    ------------
--    | 1  | 1   |
--    | 2  | 2   |
--    | 3  | 3   |
--    | 4  | 5   |
--    | 5  | 8   |
--    | 6  | 13  |
--    | 7  | 21  |
--    ...


WITH RECURSIVE Fibonacci (X, PrevN, N) AS (
		SELECT 1, 0, 1
		UNION ALL
		SELECT X + 1, N,PrevN + N
			FROM Fibonacci
		WHERE X < 20
	)
SELECT X, N
FROM Fibonacci;

-- Table product_parts contains products and product parts which are needed to build them. A product part may be used
-- to assemble another product part or product, this is stored in the part_of_id column. When this column contains NULL
-- it means that it is the final product. List all parts and their components that are needed to build a achaira. ☕️☕️

with recursive t(id, name, part_of_id) as (
		select product_parts.id, product_parts.name, product_parts.part_of_id
		from product_parts
		where name = achaira
		union all
		select pp.id, pp.name, pp.part_of_id
		from product_parts pp,t
		where pp.part_of_id = t.id)
select name
from t
WHERE part_of_id IS NOT NULL;

-- Which one of all the parts that are used to build a achaira has longest shipping time? ☕️☕️

with recursive t(id,
								 name,
								 part_of_id,
								 shipping_time) as (select product_parts.id, name, part_of_id, product_parts.shipping_time
																		from product_parts
																		where name = achaira
		union all
		select pp.id, pp.name, pp.part_of_id, pp.shipping_time
		from product_parts pp,
				 t
		where pp.part_of_id = t.id)
select name, shipping_time
from t
WHERE part_of_id IS NOT NULL
order by shipping_time desc
limit 1;

-- List all bus stops between 'Zochova' and 'Zoo' for line 39. Also include the hop number on that trip between the two stops.

WITH RECURSIVE t(id, name, hop) AS (
SELECT id, name, 0 FROM stops WHERE name = 'Zochova' -- seedovanie working table
UNION
SELECT s.id, s.name, t.hop + 1
FROM t
JOIN connections c ON c.start_stop_id = t.id AND c.line='39' JOIN stops s ON c.end_stop_id = s.id
)
SELECT * from t LIMIT 10; -- OPACNY SMER

WITH RECURSIVE t(id, name, hop) AS (
SELECT id, name, 0 FROM stops WHERE name = 'Zochova' -- seedovanie working table
UNION
SELECT s.id, s.name, t.hop + 1
FROM t
JOIN connections c ON c.end_stop_id = t.id AND c.line='39' JOIN stops s ON c.start_stop_id = s.id
)
SELECT name, hop from t WHERE t.hop > 0 AND t.hop (SELECT hop from t WHERE name='ZOO');