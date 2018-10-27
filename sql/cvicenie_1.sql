-- vystup explainu: strom jednotlivych plan nodov, kazdy zacina '->'


-- The ANALYZE option causes the statement to be actually executed, not only planned. The total elapsed time expended
-- within each plan node (in milliseconds) and total number of rows it actually returned are added to the display.
-- This is useful for seeing whether the planner's estimates are close to reality.
explain (format yaml, analyze true) select *
                                    from documents;

-- Display additional information regarding the plan. Specifically, include the output column list for each node in
-- the plan tree, schema-qualify table and function names, always label variables in expressions with their range table
--  alias, and always print the name of each trigger for which statistics are displayed. This parameter defaults to FALSE.

-- vacsi total cost ako predosly prikaz. najprv urobil filter a potom vybral vsetko zo ziskanych 8 riadkov
explain (format yaml, verbose true) select *
                                    from documents
                                    where supplier = 'SPP';

-- tu uz mame aj startup cost, zaujimave
-- vysvetlenie k startup cost z https://www.postgresql.org/docs/9.2/static/using-explain.html:
-- Estimated start-up cost. This is the time expended before the output phase can begin, e.g., time to do the sorting
-- in a sort node
-- The costs are measured in arbitrary units determined by the planner's cost parameters
-- Startup Cost: 17398.42
-- Total Cost: 17398.44

-- !!! t's important to understand that the cost of an upper-level node includes the cost of all its child nodes.
-- najprv filtroval, potom seq scan a nakoniec zoradil
explain (format yaml) select *
                      from documents
                      where supplier = 'SPP'
                      order by created_at desc;

-- najprv filtroval, potom seq scan,zoradil a limitol
explain analyze select *
                from documents
                where supplier = 'SPP'
                order by created_at desc
                limit 10;

-- Bez indexu
-- Startup Cost: 0.00
-- Total Cost: 17398.30
explain (format yaml) select *
                      from documents
                      where type = 'Egovsk::Appendix';

create index index_documents_on_type
  on documents (type);
-- s indexom:
-- Startup Cost: 0.42
--     Total Cost: 1566.25
-- musi uz pracovat so startup costom, kedze uz mame index, necita sekvencne
-- index scan
explain (format yaml) select *
                      from documents
                      where type = 'Egovsk::Appendix'; --index scan

explain (format yaml) select *
                      from documents
                      where type = 'Crz::Appendix'; -- bitmap idx scan & bitmap heap scan

-- tu sa pouzil seq scan. pri pozreti statistiky zistime, ze mame 32171 poloziek typu 'Crz::Contract' (najviac, 91%)
-- musel by prv spracovat index, sa stale pozerat do indexu a nahodne pristupovat. ked ma taku pocetnost tejto polozky,
--  neoplati sa mu pouzit index

select *
from documents
where type = 'Crz::Contract'; -- seq scan

select type, count(*) / (select reltuples from pg_class where relname = 'documents') * 100 as count
from documents
group by type;


explain (format yaml) select type
                      from documents
                      where type = 'Egovsk::Appendix'; -- index only scan

select tablename,
       attname,
       null_frac,
       avg_width,
       n_distinct,
       correlation,
       most_common_vals,
       most_common_freqs,
       histogram_bounds
from pg_stats
where tablename = 'documents';


explain (format yaml) select *
                      from documents
                      order by published_on asc;
select *
from documents
order by published_on desc;

-- vyuzitie indexu na zoradovanie, mensi cost
-- seq scan:
-- Startup Cost: 24110.06
-- Total Cost: 24110.09
-- sort:
-- Node Type: "Sort"
-- Startup Cost: 24110.06
-- Total Cost: 24988.12
explain (format yaml) select *
                      from documents
                      order by published_on
                      limit 10;


create index index_documents_on_published_on
  on documents (published_on);

explain (format yaml) select *
                      from documents
                      order by published_on
                      limit 10;
--
-- heureka moment hore

-- Domaca uloha:

-- 1. How big is the index (in megabytes)? Hint: The query is included in example sql files.
SELECT relname, pg_size_pretty(pg_relation_size(oid)) AS "size"
FROM pg_class
where relname = 'index_documents_on_type';

-- 2. Create index on supplier. Imagine that you want to ignore case when
-- searching, so you write query select * from documents where
-- lower(supplier) = lower('SPP'); (where 'SPP' is user input that you have
-- no control over). Why doesn't postgresql use the index? Try building a new index on lowercased column value
-- create index index_documents_on_lower_supplier on documents(lower(supplier)); and run the query again. Think about
-- what happened and why postgresql can use the index now.
select *
from documents
where supplier = 'SPP';

--  Startup Cost: 0.00
--  Total Cost: 18276.36
explain (format yaml) select *
                      from documents
                      where lower(supplier) = lower('SPP');
--zle, lower je nad stlpcom, aj tak musi DB robit seq scan, pomalee
-- Riesenie:
create index index_documents_on_lower_supplier
  on documents (lower(supplier));

-- Startup Cost: 58.03
-- Total Cost: 4909.42
explain (format yaml) select *
                      from documents
                      where lower(supplier) = lower('SPP');
-- uz nemusi robit transformaciu nad vsetkymi datami
