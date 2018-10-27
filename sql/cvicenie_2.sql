-- jeden viacstlpcovy vs. viac jednostpcovych indexov - jeden viacstlpcovy index da lepsi performance ako dva jendostlpcove
-- pri viacstlp. zalezi na poradi stlpcov - filtruje sa nad mnozinami v takom poradi, v akom su uvedene v indexe
-- leading columns in the index must be listed in the corresponding where clause of the index

-- single column index (partial index w/ WHERE clause) mi pomoze s performance, ak mam napriklad tabulku s milionmi
-- riadkov, ale moje queries budu pracovat iba nad malou castou riadkov.
-- resp. zaujima ma iba mensia cast dat (vzhladom na dopyty)
-- priklad:
-- CREATE INDEX idx_new_orders
--   ON oders (customer_id)
--   where order_status = 'new';



explain (format yaml) select *
                      from paragraph p
                             inner join character c on p.charid = c.charid;
-- ekvivalent
select *
from paragraph p,
     character c
where p.charid = c.charid;

-- pomocou aliasov mozem (okrem ineho) vyberat z rovnakej tabulky dvakrat

explain (format yaml) select *
                      from paragraph p
                             join character c on p.charid = c.charid;

set enable_hashjoin = off;
set enable_mergejoin = off;

explain (format yaml) select *
                      from character c
                             join paragraph p on p.charid = c.charid;

-- veci,kt. selectujem, musia byt v group by( ak by som tu pridal description, mozu mat viaceri soldieri iny desc a QP by ho vybral nahodne, resp. nevedel vybrat - bullshit)
select count(*) as count, charname
from character
group by charname
having count(*) > 1;

-- agregacna funkcia
select count(*) as count, charname, array_agg(description)
from character
group by charname
having count(*) > 1;

-- nemozmne pouzit index
select count(*) as count, charname, array_agg(description)
from character
group by charname
having count(*) > 1
    where description like '% to brutus';
-- mozme pouzit index --dokoncit
select count(*) as count, charname, array_agg(description)
from character
group by charname
having count(*) > 1
    where description like '% to suturb brutus'