--- This function creates a new table 'new_table' taking as basis the structure of the 'source_table'. 
--- Taken from here: https://stackoverflow.com/questions/23693873/how-to-copy-structure-of-one-table-to-another-with-foreign-key-constraints-in-ps
--- Important assumption: source table foreign keys have correct names i.e. their names contain source table name (what is a typical situation).
--- Example usage: 
---     create table base_table (base_id int primary key);
---     create table source_table (id int primary key, base_id int references base_table);
---     select create_table_like('source_table', 'new_table');


create or replace function create_table_like(source_table text, new_table text)
returns void language plpgsql
as $$
declare
    rec record;
begin
    execute format(
        'create table %s (like %s including all)',
        new_table, source_table);
    for rec in
        select oid, conname
        from pg_constraint
        where contype = 'f' 
        and conrelid = source_table::regclass
    loop
        execute format(
            'alter table %s add constraint %s %s',
            new_table,
            replace(rec.conname, source_table, new_table),
            pg_get_constraintdef(rec.oid));
    end loop;
end $$;