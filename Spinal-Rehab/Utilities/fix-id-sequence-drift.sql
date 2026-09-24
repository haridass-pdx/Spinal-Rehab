-- fix-id-sequence-drift.sql
--
-- Checks every SERIAL/IDENTITY column in the public schema and advances its
-- sequence to match the table's actual MAX(id) whenever the sequence has
-- fallen behind. Only touches sequences that are actually behind; sequences
-- already at or ahead of the table max are left untouched. Safe to re-run
-- any time (idempotent).
--
-- Cause: a sequence only advances when nextval() is actually called, which
-- happens automatically when you omit the id column and let SERIAL/IDENTITY
-- supply it. Anything that inserts an EXPLICIT id bypasses that — bulk
-- imports (COPY, CSV loaders), migration scripts that INSERT ... VALUES
-- (id, ...), or restoring a data-only dump without re-running its setval()
-- statements. The sequence never finds out those ids were consumed, so a
-- later organic insert can request a value that was already used, and fails
-- with a duplicate-key error — often well after the import, once normal
-- inserts catch up to the gap.
--
-- Run in any Postgres client (psql, pgAdmin, DataGrip, TablePlus, ...).
-- Output appears as NOTICE messages; no output means nothing was behind.

DO $$
DECLARE
    r RECORD;
    seq_name TEXT;
    cur_max BIGINT;
    seq_val BIGINT;
BEGIN
    FOR r IN
        SELECT n.nspname AS schema_name, c.relname AS table_name, a.attname AS column_name
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r'
          AND n.nspname = 'public'
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND pg_get_serial_sequence(n.nspname || '.' || c.relname, a.attname) IS NOT NULL
    LOOP
        seq_name := pg_get_serial_sequence(r.schema_name || '.' || r.table_name, r.column_name);
        EXECUTE format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I', r.column_name, r.schema_name, r.table_name) INTO cur_max;
        SELECT last_value INTO seq_val FROM pg_sequences
            WHERE schemaname = r.schema_name AND sequencename = split_part(seq_name, '.', 2);
        IF seq_val < cur_max THEN
            EXECUTE format('SELECT setval(%L, %s)', seq_name, cur_max);
            RAISE NOTICE 'Fixed %.%: sequence was %, table max is % — advanced to %',
                r.table_name, r.column_name, seq_val, cur_max, cur_max;
        END IF;
    END LOOP;
END $$;
